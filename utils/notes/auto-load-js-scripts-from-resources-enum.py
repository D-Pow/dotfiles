from app.utils.Classes import ValueEnum
from app.utils.Constants import get_resource_path

# Classes.py
from enum import EnumMeta, Enum

class _EnumDirectValueMeta(EnumMeta):
    def __getattribute__(cls, name):
        value = super().__getattribute__(name)
        if isinstance(value, cls):
            value = value.value
        return value

class ValueEnum(Enum, metaclass=_EnumDirectValueMeta):
    """
    Better version of the <enum.Enum> class except without
    needing to call `.value`
    """
    pass




# Constants.py
from os import path
import resources

_resources_package_name = resources.__name__

def get_resource_path(file_path='', abs_path=False):
    if abs_path:
        abs_path_to_resources = path.dirname(resources.__file__)
        return path.abspath(path.join(abs_path_to_resources, file_path))

    return path.join(_resources_package_name, file_path)





class JsScripts(ValueEnum):
    GetAllElementsEventListenersForPage = 'getAllElementsEventListenersForPage.js'
    GetElementMaxWidthAndHeight = 'getElementMaxWidthAndHeight.js'
    GetElementCssProperties = 'getElementCssProperties.js'

    def __new__(cls, js_file_name):
        enum_instance = object.__new__(cls)
        js_resource_dir = 'js'
        rel_path = f'{js_resource_dir}/{js_file_name}'
        abs_path = get_resource_path(rel_path, True)

        with open(abs_path, 'r') as js_file:
            js_script = js_file.read()
            enum_instance._value_ = js_script

        enum_instance.js_file = js_file_name

        return enum_instance

    def __repr__(self):
        return f'<{self.__class__.__name__}.{self._name_}: {self.js_file}>'
