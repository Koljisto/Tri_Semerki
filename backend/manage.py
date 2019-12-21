import pymongo
from tornado.web import Application, StaticFileHandler
from tornado.websocket import WebSocketHandler
from tornado.ioloop import IOLoop

from collections import defaultdict
from typing import Any, Dict, List
from json import loads
from functools import wraps
from time import perf_counter
from random import choice
from string import digits
from smtplib import SMTP_SSL

database_client = pymongo.MongoClient(host='localhost', port=27017)
API_METHODS = {}

def register_api(func):
    API_METHODS[func.__name__] = func
    return func

class EMailSender(object):
    _email_client = None

    @classmethod
    def _login(cls):
        cls._email_client = SMTP_SSL(host='smtp.gmail.com', port=465)
        cls._email_client.login('scrapebot.test@gmail.com', 'alpha_beta')

    @classmethod
    def send_mail(cls, *args):
        if cls._email_client is None:
            cls._login()
            
        try:
            cls._email_client.sendmail(*args)
        except:
            cls._login()
            try:
                cls._email_client.send_mail(*args)
            except:
                raise

async def check_login(username, password):
    return database_client.local.users.find_one({
        'username': username,
        'password': password
    })

async def user_in_db(username):
    return database_client.local.users.find_one({
        'username': username
    })

def require_auth(func):
    @wraps(func)
    async def inner(self, id_, *args, **kwargs):
        if self.username:
            await func(self, id_, *args, **kwargs)
        else:
            self.generate_error(-1, 'NEED_AUTH')
    
class Activation(object):
    def __init__(self, username, password, email):
        self.username = username
        self.password = password
        self.email = email

        self.time = perf_counter()
        
    def __hash(self):
        return hash(self.username)

class WSHandler(WebSocketHandler):
    online_users: Dict[str, List['WSHandler']] = defaultdict(list)
    outgoing_activations: Dict[str, Activation] = {}
    
    def initialize(self, guest_session=False):
        self.username = None
        self.guest_session = guest_session
    
    async def open(self, username = None, password = None):
        if not self.guest_session:
            if await check_login(username, password):
                WSHandler.online_users[username].append(self)
                self.username = username
                self.write_message("AUTH_SUCCESSFUL")
            else:
                self.write_message("AUTH_FAILED")
        else:
            self.write_message("GUEST_SESSION")

    async def call_api(self, func, id_, **data):
        try:
            await func(self, id_, **data)
        except RuntimeError:
            self.generate_error(-1, 'INTERNAL_ERROR')
    
    def on_message(self, message):
        try:
            data = loads(message)
        except RuntimeError:
            self.close(1003)
            return

        try:
            action = data['action']
        except RuntimeError:
            self.close(1003)
            return

        try:
            id_ = data['id']
        except KeyError:
            self.generate_error(-1, 'ID_NOT_SPECIFIED')
            return

        if action not in API_METHODS:
            self.close(1008)
            return

        del data['action']
        del data['id']

        IOLoop.current().spawn_callback(
            self.call_api, API_METHODS[action], id_, **data)
            
    def on_connection_close(self):
        if self.username:
            if self in WSHandler.online_users[self.username]:
                WSHandler.online_users[self.username].remove(self)

    def generate_success(self, id_, code='GENERATE_SUCCESS', data: Any=None):
        self.write_message({
            'id': id_,
            'status': 'success',
            'code': code,
            'data': data or {}
        })

    def generate_error(self, id_, code='GENERIC_ERROR', data: Any = None):
        self.write_message({
            'id': id_,
            'status': 'fail',
            'code': code,
            'data': data or {}
        })

    @classmethod
    def clear_old_activations(cls):
        cls.outgoing_activations = {
            key: activation
            for key, activation in cls.outgoing_activations.items()
            if perf_counter() - activation.time < 15 * 60
        }

    @register_api
    async def register(self, id_, username=None, password=None, email=None):
        self.clear_old_activations()

        if any(
            (activation.username == username or activation.email == email)
            for activation in self.outgoing_activations.values()
        ):
            self.generate_error(id_, 'ACTIVATION_IN_PROGRESS')
        elif await user_in_db(username):
            self.generate_error(id_, 'USER_ALREADY_EXISTS', data=username)
        else:
            generated_key = ''.join(choice(digits) for _ in range(6))
            self.outgoing_activations[generated_key] = Activation(
                username, password, email
            )

            EMailSender.send_mail(
                'Despair Bot',
                [email],
                (
                    "From: Despair Bot\n"
                    f"To: {email}\n"
                    "Subject: Activation\n"
                    "\n"
                    "Somebody has used this email to register at Despair app. "
                    "If this doesn't look familiar, ignore this email.\n"
                    f"Enter this key to accept: {generated_key}"
                )
            )
            self.generate_success(id_)
    
    @register_api
    async def activate(self, id_, key=None):
        self.clear_old_activations()

        if key not in self.outgoing_activations:
             self.generate_error(id_, 'INVALID_KEY')
        else:
            activation = self.outgoing_activations[key]
            database_client.local.users.insert_one({
                'username': activation.username,
                'password': activation.password,
                'email': activation.email
            })
            self.generate_success(id_)
            del self.outgoing_activations[key]
            
app = Application(
    [
        ('/websocket/([a-zA-Z0-9_]+)/([a-f0-9]{64})', WSHandler, {'guest_session': False}),
        ('/websocket', WSHandler, {'guest_session': True}),
    ],
    websocket_ping_interval=5,
    websocket_ping_timeout=300
)

app.listen(8010)
print("huy")
IOLoop.current().start()
                
            





        
        
