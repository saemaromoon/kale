from requests import get
from enum import auto, IntEnum
from importlib.machinery import ModuleSpec
from urllib.parse import urljoin
from os.path import join
import sys

class GithubImportState(IntEnum):
    USER = auto()
    REPO = auto()
    FILE = auto()

class GithubImportFinder:
    def __init__(self, gitid='', token=''):
        self.gitid = gitid
        self.token = token
        
    def find_spec(self, modname, path=None, mod=None): 
        package, dot, module = modname.rpartition(".")
#         print(f"info {modname}, {package}, {dot}, {module}") 
        if not "zigbang" in modname:
            return None
        modname = modname.replace("big_data_research", "big-data-research")
        modname = modname.replace("big_data_research_public", "big-data-research-public")
        # print(modname)
        if not dot:
            spec = ModuleSpec(
                modname,
                GithubImportLoader(),
                origin="https://github.com/" + module,
                loader_state=GithubImportState.USER,
                is_package=True)
            spec.submodule_search_locations = []
            return spec
        else:
            user, dot2, repo = package.rpartition(".") 
            if not dot2:
                spec = ModuleSpec(
                    modname,
                    GithubImportLoader(),
                    origin="https://github.com/" + "/".join([package, module]),
                    loader_state=GithubImportState.REPO,
                    is_package=True)
                spec.submodule_search_locations = []
                return spec
            path = urljoin("https://raw.githubusercontent.com",
                           join(user, repo, "master", module + ".py"))
            return ModuleSpec(
                modname,
                GithubImportLoader(self.gitid, self.token),
                origin=path,
                loader_state=GithubImportState.FILE)

class GithubImportLoader:
    def __init__(self, gitid = '', token=''):
        self.token = token
        self.gitid = gitid

    def create_module(self, spec):
        return None  # default semantics

    def exec_module(self, module):
        path = module.__spec__.origin
        if module.__spec__.loader_state != GithubImportState.USER:
            setattr(sys.modules[module.__package__],
                    module.__name__.rpartition(".")[-1], module)
        if module.__spec__.loader_state == GithubImportState.FILE:
            # load the module
            print(path) 
            code = get(path, auth=(self.gitid, self.token))
            if code.status_code != 200:
                print(path, code)
                raise ModuleNotFoundError(f"No module named {module.__name__}")
            code = code.text
            exec(code, module.__dict__) 