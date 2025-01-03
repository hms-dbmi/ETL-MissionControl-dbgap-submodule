import os, json, logging, os, subprocess, datetime
from subprocess import *

# set project home variable
projecthome = os.environ.get('ETL_PROJECT_HOME', './') # sets where script is executed if envvar is not set
print('Project Home is set to ' + projecthome) 
# set variables
with open(projecthome + '/runpartition.json') as json_data:
    data = json.load(json_data)
    # Infrastructure variables
    resourcesdir = data.get('resourcesdir', projecthome +'/resources/')
    datadir = data.get('datadir', projecthome +'/data/')
    studybucket = data.get('studybucket', '')
    mappingdir = data.get('mappingdir', projecthome +'/mappings/')
    writedir = data.get('writedir', projecthome +'/completed/')
    jobconfig = data.get('jobconfig', projecthome +'/resources/')
    mappingfilename = data.get('mappingfilename', projecthome +'/mapping.csv')
    patientmappingfilename = data.get('patientmappingfilename', projecthome +'/mapping.csv.patient')
    patientconfig = data.get('patientconfig', projecthome +'/resources/patient.config')
    maxjobs = data.get('maxjobs', 10)
    jobmemory = data.get('jobmemory', '2g')
    trialid = data.get('trialid', 'default')
    
    # Job variables
    #syncproject = data.get('syncproject', 'N').upper()
    #runcurator = data.get('runcurator', 'Y').upper()
    #rundataeval = data.get('rundataeval', 'Y').upper()
    #runpartitioning = data.get('runpartitioning', 'Y').upper()
    rungenerator = data.get('rungenerator', 'Y').upper()
    #rundataload = data.get('rundataload', 'Y').upper()

    # Logging variables
    loglevel = (getattr(logging, data.get('loglevel', 'INFO').upper(), None))
    logdir = data.get('logdir', '/var/logs/')
    clearlogs = data.get('clearlogs', 'Y').upper()
    archivelogs = data.get('archivelogs', 'N').upper()


#logging
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
        
#create loggers
if clearlogs == 'Y':
    if archivelogs == 'Y':
        ts = datetime.datetime.now().isoformat()
        if os.path.isfile(logdir + 'main.log'):
            os.rename(logdir + 'main.log', logdir + ts +'_main.log')
        if os.path.isfile(logdir + 'errorlogger.log'):
            os.rename(logdir + 'errorlogger.log', logdir + ts +'_errorlogger.log')
        mainlogger = setup_logger('mainlogger',logdir + 'main.log', loglevel, logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
        errorlogger = setup_logger('errorlogger',logdir + 'errorlogger.log', loglevel, logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
    else:
        if os.path.isfile(logdir + 'main.log'):
            os.remove(logdir + 'main.log')
        if os.path.isfile(logdir + 'errorlogger.log'):
            os.remove(logdir + 'errorlogger.log')
        mainlogger = setup_logger('mainlogger',logdir + 'main.log', loglevel, logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
        errorlogger = setup_logger('errorlogger',logdir + 'errorlogger.log', loglevel, logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
else:
    mainlogger = setup_logger('mainlogger',logdir + 'main.log', loglevel, logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
    errorlogger = setup_logger('errorlogger',logdir + 'errorlogger.log', loglevel, logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
    
def cmdWrapper(*args):
    process = subprocess.Popen(list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    return stdout,stderr

## Data Sync
#  Syncs a project's bucket 
#if syncproject == 'Y':
#    args = ['aws', 's3', 'sync', str(studybucket), projecthome]
#    mainlogger.info('Starting: ' + ' '.join(args))
#    stdout,stderr = cmdWrapper(*args)
#    logmsgs(mainlogger, stdout, stderr)
#    mainlogger.info('Finished: ' + ' '.join(args))
    
## main
# Data Curator
#if runcurator == 'Y':
#    args = ['java', '-jar', 'DataCurator.jar', '-propertiesfile', jobconfig]
#    mainlogger.info('Starting: ' + ' '.join(args))
#    stdout,stderr = cmdWrapper(*args)
#    logmsgs(mainlogger, stdout, stderr)
#    mainlogger.info('Finished: ' + ' '.join(args))
    #mainlogger.info(''.join(stdout))
    #mainlogger.error(''.join(stderr))      
## Data Evaluations
#if rundataeval == 'Y':
#    args = ['java', '-jar', 'DataEvaluation.jar', '-propertiesfile', jobconfig]
#    mainlogger.info('Starting: ' + ' '.join(args))
#    stdout,stderr = cmdWrapper(*args)
#    logmsgs(mainlogger, stdout, stderr)
#    mainlogger.info('Finished: ' + ' '.join(args))
    #mainlogger.info(''.join(stdout))
    #mainlogger.error(''.join(stderr))  
## Partitioner
#if runpartitioning == 'Y':
#    args = ['java', '-jar', 'Partitioner.jar', '-propertiesfile', jobconfig]
#    mainlogger.info('Starting: ' + ' '.join(args))
#    stdout,stderr = cmdWrapper(*args)
#    logmsgs(mainlogger, stdout, stderr)
#    mainlogger.info('Finished: ' + ' '.join(args))

## Generate Patients
#if rungenerator == 'Y':
#    args = ['java', '-jar', 'PatientGenerator.jar', '-propertiesfile', jobconfig ]
#    mainlogger.info('Starting: ' + ' '.join(args))
#    stdout,stderr = cmdWrapper(*args)
#    logmsgs(mainlogger, stdout, stderr)
#    mainlogger.info('Finished: ' + ' '.join(args))

## Sequence Patients
#    args = ['java', '-jar', 'PatientSequencer.jar', '-propertiesfile', jobconfig ]
    
#    mainlogger.info('Starting: ' + ' '.join(args))
#    stdout,stderr = cmdWrapper(*args)
#    logmsgs(mainlogger, stdout, stderr)
#    mainlogger.info('Finished: ' + ' '.join(args))

    
## Process partitions this will generate the rest of the entities.
    #for file in os.listdir(resourcesdir):
     #   if 'config.part' in file:
            #args = ['java', '-jar', 'EntityGenerator.jar', '-propertiesfile', resourcesdir + file, '-jobtype', 'CSVToI2b2TM' ]
args = ['sh', 'runpartition.sh', '-j', str(maxjobs), '-m', jobmemory, '-c', 'config.part*.config', '-r', resourcesdir]        

mainlogger.info('Starting: ' + ' '.join(args))
stdout,stderr = cmdWrapper(*args)
logmsgs(mainlogger, stdout, stderr)
mainlogger.info('Finished: ' + ' '.join(args))

## Process Fill in Tree
#    args = ['java', '-jar', 'FillInTree.jar', '-propertiesfile', jobconfig ]
    
#    mainlogger.info('Starting: ' + ' '.join(args))
#    stdout,stderr = cmdWrapper(*args)
#    logmsgs(mainlogger, stdout, stderr)
#    mainlogger.info('Finished: ' + ' '.join(args))

## Process Concept Counts
#    args = ['java', '-jar', 'CountGenerator3.jar', '-propertiesfile', jobconfig ]
    
 #   mainlogger.info('Starting: ' + ' '.join(args))
  #  stdout,stderr = cmdWrapper(*args)
   # logmsgs(mainlogger, stdout, stderr)
    #mainlogger.info('Finished: ' + ' '.join(args))


## Run data cleanup
#    args = ['java', '-jar', 'DataCleanUp.jar', '-datadir', datadir ]
    
#    mainlogger.info('Starting: ' + ' '.join(args))
#    stdout,stderr = cmdWrapper(*args)
#    logmsgs(mainlogger, stdout, stderr)
#    mainlogger.info('Finished: ' + ' '.join(args))

#if rundataload == 'Y':
#    args = ['sh', 'LoadTables.sh', '-u', str(dburl), '-o', dbuser, '-p', dbpass, '-c', writedir, '-s', dbscriptdir]        
#    mainlogger.info('Starting: ' + ' '.join(args))
#    stdout,stderr = cmdWrapper(*args)
#    logmsgs(mainlogger, stdout, stderr)
#    mainlogger.info('Finished: ' + ' '.join(args))