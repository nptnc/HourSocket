import asyncio
import json
import logging
import websockets.server as server
import datetime
from websockets import exceptions

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
        "total_packets_received": 0,
    },
    "players": {},
    "world": {
        "entities": {},
        "state": "Start"
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
        }
    })
    websockets.update({
        userid: ws
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
async def doAttack(ws, userid: int, attack: str, arg1: float = None, arg2: float = None):
    await send_all_ws(create_message(
        4, userid, attack, arg1, arg2 # we dont know what arg1 or 2 is ☠️💀☠️💀☠️💀
    ), except_for=[userid])
doAttack()

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
async def playAnimation(ws, userid: int, arg1: float, animationname: str):
    await send_all_ws(create_message(
        8, userid, arg1, animationname
    ), except_for=[userid])
playAnimation()

@createPacket(9)
async def updateEntityState(ws, userid: int, entityid: int, key: str, value: any):
    if not data['players'][userid]['isHost']:
        logger.warning(f"{userid} is not allowed to update entity states!")
        return
    data['entities'][entityid].update({
        key: value,
    })
    await send_all_ws(create_message(
        9, entityid, key, value
    ))
    if key == "health" and value <= 0:
        del data['entities'][entityid]
        logger.debug(f"Deleted entity {entityid} because it fucking died")

updateEntityState()

async def handler(ws: server.WebSocketServerProtocol):
    while True:
        try:
            message = await ws.recv()
            data['statistics']['total_packets_received'] += 1
        except (exceptions.ConnectionClosedOK, exceptions.ConnectionClosedError, exceptions.ConnectionClosed, ConnectionResetError):
            socket_id = await ws_to_userid(ws)
            if socket_id is None:
                return
            return await packet_handlers.get(0)(ws,socket_id)
        message = str(message).split(":::")
        message_type = int(message.pop(0))
        if packet_handlers.get(message_type) is None:
            logger.warning(f"Message type {message_type} is unregistered, did you forget to call it?")
            return await ws.send(create_message(
                999,"Unregistered Message Type",0
            ))
        await packet_handlers.get(message_type)(ws,*message)
        

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