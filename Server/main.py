import asyncio
import json
import logging
import websockets.server as server
import datetime
from websockets import exceptions
import inspect


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
webclients = []

def createPacket(message_type: int):
    def handler_create(handler):
        def wrapper():
            if message_type in packet_handlers:
                return logger.warning(f"{message_type} is already registered as {packet_handlers[message_type].__name__}")
            packet_handlers.update({
                message_type: handler
            })
            logger.info(f"Registered {handler.__name__} as message type {message_type}")
        wrapper()
        return wrapper
    return handler_create

class Message:
    def __init__(self, *args: str, message_type: int = None, loopback: bool = False, recipients: list = None, associated_user: int = None):
        self.caller = inspect.stack()[1][0].f_code.co_name
        self.type = message_type
        if self.type is None:
            self.type = [
                handler for handler in packet_handlers 
                if packet_handlers[handler].__name__ == self.caller
            ][0] if self.caller in packet_handlers else None
        self.associated_user = associated_user
        self.content = (
            f"{self.type}:::{f'{associated_user}:::' if associated_user else ''}"
            + ':::'.join(list(args))
        )
        self.loopback = loopback
        self.recipients = [
            recipient for recipient in recipients 
            if recipient in websockets and (recipient != associated_user and not loopback)
        ] if recipients is not None else None

    def edit(self, *args):
        """This shouldn't ever need to be used, but its here just in case it is."""
        self.content = str(self.type) + ':::'.join(list(args))

    async def send(self, include_webclients: bool = False, auto_dispose: bool = True):
        if self.type is None:
            return logger.warning(f"[Function: {self.caller}] sent a message with no type.")
        if self.recipients == []:
            return logger.warning(f"[Function: {self.caller}] no valid recipients.")
        if self.recipients is None:
            return logger.warning(f"[Function: {self.caller}] sent a message with no recipients?")
        for recipient in self.recipients:
            websockets[recipient].send(self.content)
        if self.loopback and self.associated_user is not None:
            websockets[self.associated_user].send(self.content)
        if include_webclients:
            for client in webclients:
                client.send(self.content)
        if not auto_dispose:
            return
        del self

async def giggle_gaggle():
    message = await Message(
        "",
        message_type=0, loopback=True, 
    )

    print(message.content)

    await message.send()

# asyncio.run(giggle_gaggle())

async def ws_to_userid(_ws):
    for ws in websockets:
        if websockets[ws] == _ws:
            return ws
    return


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


@createPacket(-1)
async def getWebData(ws):
    logger.debug("New web server connection!")
    webclients.append(ws)
    while not ws.closed:
        try:
            await ws.send(json.dumps(data))
            await asyncio.sleep(1/60)
        except exceptions.ConnectionClosed:
            logger.debug("A web server disconnected.")

@createPacket(0)
async def disconnectPlayer(ws, userid: int):
    if userid not in data['players']:
        return logger.warning(f"{userid} is not connected. Can't disconnect a player that wasn't connected in the first place.")
    del data['players'][userid]
    del websockets[userid]
    await Message(
        recipients=list(websockets), associated_user=userid
    ).send(include_webclients=True)
    logger.info(f"Disconnected player {userid}")
    if len(data['players']) == 0:
        data['world'].update({
            "entities": {}
        })
        logger.info("Clearing entity list because there are no players connected!")

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
    await Message(
        json.dumps(data['players']),
        recipients=[userid]
    ).send()
    await Message(
        json.dumps(data['players'][userid]),
        recipients=list(websockets), associated_user=userid
    ).send()
    logger.info(f"Registered player {username}({userid})")

@createPacket(2)
async def updatePlayerPosition(ws, userid: int, pos_x: float, pos_y: float, pos_z: float, rot_x: float, rot_y: float, rot_z: float):
    if userid not in data['players']:
        return
    data['players'][userid].update({
        "position": [pos_x,pos_y,pos_z],
        "rotation": [rot_x,rot_y,rot_z],
    })
    await Message(
        2, pos_x,pos_y,pos_z,rot_x,rot_y,rot_z,
        recipients=list(websockets), associated_user=userid
    ).send()

@createPacket(3)
async def updatePlayerState(ws, userid: int, key: str, value: any):
    data['players'][userid].update({
        key: value,
    })
    await Message(
        3, key, value,
        recipients=list(websockets), associated_user=userid
    ).send()
    if key == "dead" and value:
        for player in data['players']:
            if not data['players'][player]['dead']:
                return
        data['world'].update({
            "entities": {}
        })
        logger.info("Clearing entities because all players died.")

@createPacket(4)
async def updateKnockback(ws, userid: int, knockbackIndex: int, x: float, y: float, z: float):
    await Message(
        knockbackIndex,x,y,z,
        recipients=list(websockets), associated_user=userid
    ).send()

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
    await Message(
        entityid, entityname, team, is_boss, pos_x, pos_y, pos_z, rot_x, rot_y, rot_z,
        recipients=list(websockets)
    ).send()
    logger.debug(f"Registered {entityname}({entityid}) as an entity.")

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
    
    await Message(
        entityid, pos_x, pos_y, pos_z, rot_x, rot_y, rot_z,
        recipients=list(websockets)
    ).send()

@createPacket(7)
async def updateWorldState(ws, userid: int, newstate: str):
    if not data['players'][userid]['isHost']:
        logger.warning(f"{userid} is not allowed to update the world state!")
        return
    data['world'].update({
        "state": newstate
    })
    await Message(
        newstate,
        recipients=list(websockets)
    ).send()

@createPacket(8)
async def doInput(ws, userid: int, _input: str, pos_x: float = 0, pos_y: float = 0, pos_z: float = 0, rot_x: float = 0, rot_y: float = 0, rot_z: float = 0):
    await Message(
        _input, pos_x, pos_y, pos_z, rot_x, rot_y, rot_z,
        recipients=list(websockets), associated_user=userid
    ).send()

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
    await Message(
        entityid, key, value,
        recipients=list(websockets)
    ).send()
    if key == "health" and float(value) <= 0:
        del data['world']['entities'][entityid]
        logger.debug(f"Deleted entity {entityid} because it fucking died")

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
        await Message(
            data['players'][player]['pickedIndex'],
            recipients=player
        ).send()

@createPacket(11)
async def startTempo(ws, userid: int, timePower: str, special: int):
    if userid not in data['players']:
        return
    # await send_all_ws(create_message(
    #     11, timePower, special
    # ))#, except_for=[userid])

@createPacket(12)
async def updateEntityKnockback(ws, userid: int, entityid: int, knockbackIndex: int, x: float, y: float, z: float):
    await Message(
        entityid, knockbackIndex, x, y, z,
        recipients=list(websockets)
    ).send()

@createPacket(13)
async def talentPopup(ws, userid: int, isArena: bool):
    await Message(
        isArena,
        recipients=list(websockets)
    )

@createPacket(14)
async def damageRequest(ws,userid: int, entityid: int, damage: int, partname: str, damagename: str = None, screenshake: int = 0):
    if userid not in data['players']:
        return
    await Message(
        entityid, damage, partname, damagename, screenshake,
        recipients=[ws_to_userid(data['world']['host'])], associated_user=userid
    )

@createPacket(15)
async def entityInput(ws, userid: int, entityId: int, someIndex: int, _input: str):
    if not data['players'][userid]["isHost"]:
        return
    await Message(
        entityId, someIndex, _input,
        recipients=list(websockets)
    ).send()

@createPacket(16)
async def sayChatMsg(ws, userid: int, chat_message: str):
    await Message(
        chat_message,
        recipients=list(websockets), associated_user=userid
    ).send()

async def handle_incoming(ws):
    try:
        raw_msg = await ws.recv()
    except (exceptions.ConnectionClosed, ConnectionResetError):
        return await packet_handlers.get(0)(ws,socket_id) if (socket_id := await ws_to_userid(ws)) is not None else None
    data.get('statistics')["packets_received"] += 1
    msg = str(raw_msg).split(":::")
    msg_type = int(msg.pop(0))
    return await packet_handlers.get(msg_type)(ws,*msg) if msg_type is not None else None

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