import os
from jupyterhub.handlers import BaseHandler
from jupyterhub.auth import Authenticator
from jupyterhub.utils import url_path_join
from tornado import gen, web
from traitlets import Unicode

class RemoteUserLoginHandler(BaseHandler):

    def get(self):
        header_name = self.authenticator.header_name
        remote_user = self.request.headers.get(header_name, "")
        if remote_user == "":
            self.log.warn("Failed to fetch pre-authenticated user from headers")            
            raise web.HTTPError(401)
        else:
            self.log.info("Pre-authenticated user: {}".format(remote_user))            
            user = self.user_from_username(remote_user.split('@')[0])
            self.set_login_cookie(user)
            self.redirect(url_path_join(self.hub.server.base_url, 'home'))


class RemoteUserAuthenticator(Authenticator):

    """
    Accept the authenticated user name from the X-Forwarded-Remote-User HTTP header.
    """
    header_name = Unicode(
        default_value='X-Forwarded-Remote-User',
        config=True,
        help="""HTTP header to inspect for the authenticated username.""")

    def get_handlers(self, app):
        return [
            (r'/login', RemoteUserLoginHandler),
        ]

    @gen.coroutine
    def authenticate(self, *args):
        raise NotImplementedError()

