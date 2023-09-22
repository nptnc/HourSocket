import asyncio
import json
import logging
import websockets.server as server
import datetime
from websockets import exceptions


import subprocess
import re



class CustomFormatter(logging.Formatter):
    grey = "\x1b[38;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    format = "%(levelname)s - %(message)s"

    FORMATS = {
        logging.DEBUG: grey + format + reset,
        logging.INFO: grey + format + reset,
        logging.WARNING: yellow + format + reset,
        logging.ERROR: red + format + reset,
        logging.CRITICAL: bold_red + format + reset
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        return formatter.format(record)

loglevel = logging.DEBUG

logger = logging.getLogger('HOURSocket')
logger.setLevel(loglevel)
formatter = CustomFormatter()
handler_console = logging.StreamHandler()
handler_console.setLevel(loglevel)
handler_console.setFormatter(formatter)
logger.addHandler(handler_console)

packet_handlers = {}
start_time = datetime.datetime.now()

data = {
    "statistics": {
        "packets_received": 0,
        "started_at": datetime.datetime.now().strftime("%d-%m-%Y / %H:%M:%S"),
        "elapsed_runtime": "??:??:??"
    },
    "players": {},
    "world": {
        "host": None,
        "entities": {},
        "state": "Start",
    }
}

websockets = {}
webserver_websockets = []

def createPacket(message_type: int):
    def handler_create(handler):
        def wrapper():
            packet_handlers.update({
                message_type: handler
            })
            logger.info(f"Registered {handler.__name__} as message type {message_type}")
        return wrapper
    return handler_create

def create_message(message_type: int, *args: str):
    message = f"{message_type}"
    for arg in args:
        message += f":::{arg}"
    return message

async def ws_to_userid(_ws):
    for ws in websockets:
        if websockets[ws] == _ws:
            return ws
    return

async def send_all_ws(message, except_for: list = None, include_webservers: bool = False):
    if except_for is None:
        except_for = []
    for ws in websockets:
        if ws in except_for:
            continue
        try:
            await websockets[ws].send(message)
        except Exception:
            return
    if include_webservers:
        for ws in webserver_websockets:
            if not ws.closed:
                await ws.send(message)


async def GetterGetter(part: None):
    if part is None:
        for userid in data.get('players'):
            if data.get('players')[userid]['isHost']:
                return userid
    if isinstance(part,server.WebSocketServerProtocol):
        for userid in websockets:
            if websockets[userid] == part:
                return userid
    if isinstance(part,int):
        for userid in websockets:
            if userid == part:
                return websockets[userid]


async def alert(ws, error: str, error_code: int):
    logger.warning(error)
    return await ws.send(create_message(999,error,error_code))

@createPacket(-1)
async def getWebData(ws):
    logger.debug("New web server connection!")
    webserver_websockets.append(ws)
    while not ws.closed:
        try:
            await ws.send(json.dumps(data))
            await asyncio.sleep(1/60)
        except exceptions.ConnectionClosed:
            logger.debug("A web server disconnected.")
getWebData()

@createPacket(0)
async def disconnectPlayer(ws, userid: int):
    if userid not in data['players']:
        return logger.warning(f"{userid} is not connected. Can't disconnect a player that wasn't connected in the first place.")
    del data['players'][userid]
    del websockets[userid]
    await send_all_ws(create_message(0,userid), except_for=[userid], include_webservers=True)
    logger.info(f"Disconnected player {userid}")
    if len(data['players']) == 0:
        data['world'].update({
            "entities": {}
        })
        logger.info("Clearing entity list because there are no players connected!")
disconnectPlayer()

@createPacket(1)
async def registerPlayer(ws, userid: int, username: str, _class: str):
    logger.info(f"Attempting to register player with id {userid}")
    if userid in data['players']:
        return logger.info(f"{userid} is already registered on the server! Not registering.")
    data['players'].update({
        userid: {
            "username": username,
            "id": userid,
            "class": _class,
            "dead": False,
            "position": [0,0,0],
            "rotation": [0,0,0],
            "isHost": len(data['players']) == 0,
            "speed": 1,
            "picked": False,
            "pickedIndex": 0,
        }
    })
    websockets.update({
        userid: ws
    })
    data['world'].update({
        "host": ws if data['players'][userid]['isHost'] else data['world']['host']
    })
    await ws.send(create_message(
        1, -1, json.dumps(data['players'])
    ))
    await send_all_ws(create_message(
        1, userid, json.dumps(data['players'][userid])
    ), except_for=[userid])
    logger.info(f"Registered player {username}({userid})")
registerPlayer()

@createPacket(2)
async def updatePlayerPosition(ws, userid: int, pos_x: float, pos_y: float, pos_z: float, rot_x: float, rot_y: float, rot_z: float):
    if userid not in data['players']:
        return await ws.send(create_message(
            999, "Player does not exist.", 1
        ))
    data['players'][userid].update({
        "position": [pos_x,pos_y,pos_z],
        "rotation": [rot_x,rot_y,rot_z],
    })
    await send_all_ws(create_message(
        2, userid, pos_x,pos_y,pos_z,rot_x,rot_y,rot_z
    ), except_for=[userid])
updatePlayerPosition()

@createPacket(3)
async def updatePlayerState(ws, userid: int, key: str, value: any):
    data['players'][userid].update({
        key: value,
    })
    await send_all_ws(create_message(
        3, userid, key, value
    ))
    if key == "dead" and value:
        for player in data['players']:
            if not data['players'][player]['dead']:
                return
        data['world'].update({
            "entities": {}
        })
        logger.info("Clearing entities because all players died.")
updatePlayerState()

@createPacket(4)
async def updateKnockback(ws,userid: int,knockbackIndex: int,x: float,y: float,z: float):
    await send_all_ws(create_message(
        4,userid,knockbackIndex,x,y,z
    ),except_for=userid)
updateKnockback()

@createPacket(5)
async def registerEntity(ws, userid: int, entityid: int, entityname: str, team: int, is_boss: bool, pos_x: float = 0, pos_y: float = 0, pos_z: float = 0, rot_x: float = 0, rot_y: float = 0, rot_z: float = 0):
    if not data['players'][userid]['isHost']:
        logger.warning(f"{userid} is not allowed to register entities!")
        return
    if entityid in data['world']['entities']:
        logger.warning(f"{entityid} is already a registered entity!")
        return
    data['world']['entities'].update({
        entityid: {
            "name": entityname,
            "position": [pos_x,pos_y,pos_z],
            "rotation": [0,0,0],
            "health": 100,
            "isBoss": is_boss,
            "team": team,
        }
    })
    await send_all_ws(create_message(
        5, entityid, entityname, team, is_boss, pos_x, pos_y, pos_z, rot_x, rot_y, rot_z
    ), except_for=[userid])
    logger.debug(f"Registered {entityname}({entityid}) as an entity.")
registerEntity()

@createPacket(6)
async def updateEntityPosition(ws, userid: int, entityid: int, pos_x: float, pos_y: float, pos_z: float, rot_x: float, rot_y: float, rot_z: float):
    if not data['players'][userid]['isHost']:
        logger.debug(f"{userid} is not allowed to update entities!")
        return
    if entityid not in data['world']['entities']:
        logger.debug(f"{userid} is trying to update entity {entityid} but it does not exist, not updating.")
        return
    data['world']['entities'][entityid].update({
        "position": [pos_x,pos_y,pos_z],
        "rotation": [rot_x,rot_y,rot_z],
    })

    # hi peebly 👋
    await send_all_ws(create_message(
        6, entityid, pos_x, pos_y, pos_z, rot_x, rot_y, rot_z
    ), except_for=[userid])
updateEntityPosition()

@createPacket(7)
async def updateWorldState(ws, userid: int, newstate: str):
    if not data['players'][userid]['isHost']:
        logger.warning(f"{userid} is not allowed to update the world state!")
        return
    data['world'].update({
        "state": newstate
    })
    await send_all_ws(create_message(
        7, newstate
    ))
updateWorldState()

@createPacket(8)
async def doInput(ws, userid: int, input: str, pos_x: float = 0, pos_y: float = 0, pos_z: float = 0, rot_x: float = 0, rot_y: float = 0, rot_z: float = 0):
    await send_all_ws(create_message(
        8, userid, input, pos_x, pos_y, pos_z, rot_x, rot_y, rot_z
    ), except_for=[userid])
doInput()

@createPacket(9)
async def updateEntityState(ws, userid: int, entityid: int, key: str, value: any):
    if not data['players'][userid]['isHost']:
        logger.warning(f"{userid} is not allowed to update entity states!")
        return
    if entityid not in data["world"]["entities"]:
        return

    data['world']['entities'][entityid].update({
        key: value,
    })
    await send_all_ws(create_message(
        9, entityid, key, value
    ), except_for=[userid])
    if key == "health" and float(value) <= 0:
        del data['world']['entities'][entityid]
        logger.debug(f"Deleted entity {entityid} because it fucking died")
updateEntityState()

@createPacket(10)
async def pickTalentPacket(ws, userid: int, talentindex: int):
    if userid not in data['players']:
        return
    data['players'][userid].update({
        "picked": True,
        "pickedIndex": talentindex
    })
    for player in data['players']:
        if not data['players'][player]['picked']:
            return
    for player in data['players']:
        data['players'][player].update({
            "picked": False
        })
        await websockets[data['players'][player]['id']].send(create_message(
            10, data["players"][player]["pickedIndex"]
        ))
pickTalentPacket()

@createPacket(11)
async def startTempo(ws, userid: int, timePower: str, special: int):
    if userid not in data['players']:
        return
    await send_all_ws(create_message(
        11, timePower, special
    ))#, except_for=[userid])
startTempo()

@createPacket(12)
async def updateEntityKnockback(ws, userid: int, entityid: int, knockbackIndex: int, x: float, y: float, z: float):
    await send_all_ws(create_message(
        12,entityid, knockbackIndex, x, y, z
    ),except_for=userid)
updateEntityKnockback()

@createPacket(13)
async def talentPopup(ws, userid: int, isArena: bool):
    await send_all_ws(create_message(
        13, isArena
    ),except_for=userid)
talentPopup()

@createPacket(14)
async def damageRequest(ws,userid: int, entityid: int, damage: int, partname: str, damagename: str = None, screenshake: int = 0):
    if userid not in data['players']:
        return
    await data['world']['host'].send(create_message(
        14, userid, entityid, damage, partname, damagename, screenshake   
    ))
damageRequest()

@createPacket(15)
async def entityInput(ws, userid: int, entityId: int, someIndex: int, input: str):
    if not data['players'][userid]["isHost"]:
        return
    await send_all_ws(create_message(
        15, entityId, someIndex, input
    ), except_for=[userid])
entityInput()

async def handle_incoming(ws):
    try:
        raw_msg = await ws.recv()
    except (exceptions.ConnectionClosed, ConnectionResetError):
        return await packet_handlers.get(0)(ws,socket_id) if (socket_id := await ws_to_userid(ws)) is not None else None
    data.get('statistics')["packets_received"] += 1
    msg = str(raw_msg).split(":::")
    msg_type = int(msg.pop(0))
    return await packet_handlers.get(msg_type)(ws,*msg) if msg_type is not None else await alert(ws,f"Unregistered Message Type {msg_type}",0)

async def handler(ws: server.WebSocketServerProtocol):
    while True:
        elapsed_runtime = datetime.datetime.now() - datetime.datetime.strptime(data.get('statistics')['started_at'],"%d-%m-%Y / %H:%M:%S")
        data.get('statistics')['elapsed_runtime'] = str((elapsed_runtime - datetime.timedelta(microseconds=elapsed_runtime.microseconds)))

        await handle_incoming(ws)
        

async def start_socket():
    logger.info("Starting websocket.")
    async with server.serve(handler, "0.0.0.0", 7171):
        # while True:
        #     disconnect = [ws for ws in websockets if ws.closed]
        #     for socket in disconnect:
        #         await packet_handlers.get(0)(None,socket)
        #     await asyncio.sleep(2.5)
        await asyncio.Future()  # run forever


websocket = asyncio.ensure_future(start_socket())

loop = asyncio.get_event_loop().run_forever()
# asyncio.run(main())