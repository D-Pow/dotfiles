from global_config import global_config
from datasource.datasource_processor import DatasourceProcessor
from datasource.datasourceA import SomeClass

def get_all_datasource_data(global_config):
    for datasource in global_config['datasources']:
        processor = DatasourceProcessor(datasource, global_config)
        datasource_data = processor.get_module_data()
        datasource_name = processor.get_module_name()
        write_front_end_json(datasource_data, datasource_name)
        print(datasource_data)

def write_front_end_json(datasource_data, datasource_name):
    # write file
    pass

def get_module(module_name, package_name=''):
    if package_name != '' and package_name[-1] != '.':
        package_name += '.'
    import_name = package_name + module_name
    module = __import__(import_name, fromlist=[module_name])
    return module


if __name__ == "__main__":
    # get_all_datasource_data(global_config)
    module = __import__('datasource.blah', fromlist=['blah'])
    module.get_data('hi')
    # x = getattr(globals()['datasource.{}'.format('blah')], 'get_data')
    # print(x)
    x = SomeClass()
    #datasource_module = get_module('datasource_blah')
    #print(datasource_module.get_name())
    blah = __import__('datasource_blah', fromlist=['datasource_blah'])
    print(blah.get_name())
