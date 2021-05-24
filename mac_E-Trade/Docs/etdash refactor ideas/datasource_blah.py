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