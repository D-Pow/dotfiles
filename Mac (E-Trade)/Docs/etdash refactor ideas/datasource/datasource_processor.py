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