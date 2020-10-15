import os, json, logging, os, subprocess, datetime, time, csv
from subprocess import *
from fileinput import filename

###
#  Required
#  Python 3
#  Managed Inputs in ./data/ directory
#  gen3 json manifest file in ./data/ directory

### functions
def cmdWrapper(*args):
    process = subprocess.Popen(list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    process.wait()
    logmsgs(mainlogger, stdout, stderr)
    return stdout,stderr

#logging
# Logging variables
loglevel = 'INFO'
logdir = '/var/logs/'

#function to setup logging
def setup_logger(name, log_file, level=loglevel, formatter=''):
    """Function setup as many loggers as you want"""

    handler = logging.FileHandler(log_file)
    handler.setFormatter(formatter)

    logger = logging.getLogger(name)
    logger.setLevel(level)
    logger.addHandler(handler)

    return logger

def logmsgs(logger, stdout, stderr):
    if stdout is not None or stdout != '':
        logger.info(''.join(stdout))
    if stderr is not None or stderr != '':
        logger.info(''.join(stderr))

# Initialize loggers
mainlogger = setup_logger('mainlogger','main.log', loglevel, logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
errorlogger = setup_logger('errorlogger','errorlogger.log', loglevel, logging.Formatter('%(asctime)s %(levelname)s %(message)s'))


# get all phs values from managed input
managed_inputs = csv.DictReader(open("./data/Managed_Inputs.csv"))

phs_list = {}

for managed_input in managed_inputs:
    phs_list[managed_input['Study Identifier']] = managed_input['Study Abbreviated Name']

json_data = json.loads(open('data/file-manifest.json').read())

for o in json_data:
    if o['file_name'].split(".")[0] in phs_list:
        study_name = phs_list[o['file_name'].split(".")[0]]

        args = ['gen3-client' ,'download-single', '--profile=demo', '--guid=' + o['object_id'], '--download-path', 'downloads', '--no-prompt']
        print(args)
        stdout,stderr = cmdWrapper(*args)

        for filename in os.listdir('downloads'):

            if(filename.endswith(".gz")):
                args = ['gzip', '-d',  'downloads/' + filename]
                print(args)
                stdout,stderr = cmdWrapper(*args)

            args = ['aws', 's3', 'cp', 'downloads/', "s3://avillach-73-bdcatalyst-etl/" + study_name.lower()  + '/rawData/', '--recursive']
            print(args)
            stdout,stderr = cmdWrapper(*args)
            print(stdout)

            args = ['rm', '-rf', 'downloads/']
            print(args)
            stdout,stderr = cmdWrapper(*args)
            print(stdout)

