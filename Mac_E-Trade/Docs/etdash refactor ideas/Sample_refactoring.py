#####    *global_config.py*   #####
_base_dir = "/some/path"
global_config = {
    'bin_dir': '{}/premarket/_bin'.format(_base_dir),
    'use_caching': 0,
    'some_global_config': 'some_global_data',
    'datasources': [
        'datasource'
    ],
    'global_services_config': '...'
}




#####    *premarket.py*   #####
from global_config import global_config
from datasource_processor import DatasourceProcessor

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

if __name__ == "__main__":
    get_all_datasource_data(global_config)




#####    *datasource_processor.py*   #####
class DatasourceProcessor:
    def __init__(self, datasource_string, global_config):
        self._datasource_string = datasource_string
        self._global_config = global_config
        self._bin_dir = global_config['bin_dir']
        self._use_caching = global_config['use_caching']
        self._module = __import__(datasource_string)

    def get_module_data(self):
        if not self._use_caching:
            datasource_data = self._module.get_data(self._global_config)
            datasource_name = self._module.get_name()
            self._module_cache_data(datasource_name, datasource_data)
            return datasource_data
        else:
            return "Data from cache.json file"

    def get_module_name(self):
        return self._module.get_name()
    
    def _module_cache_data(self, datasource_name, datasource_data):
        data_cache_file = "{}/data/{}_cache.json".format(
            self._bin_dir,
            datasource_name
        )
        # json.dump(datasource_data)
        print("Wrote cache to {}".format(data_cache_file))




#####    *datasource.py*.   #####
datasource_config = {
    'name': 'datasource',
    'service': 'my_critical_service',
    'file_path': '/some/path',
    'queue_names': ['some', 'queues'],
    'other_config': '...'
}

def get_data(global_config):
    some_data = "Here's some data from global_config and datasource: {} + {}"
    return_json = some_data.format(
        global_config['some_global_config'],
        datasource_config['service']
    )
    return return_json

def get_name():
    return "{}_{}".format(datasource_config['name'], datasource_config['service'])