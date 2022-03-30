package etl.jobs.csv.bdc;

import java.io.BufferedWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

import etl.job.entity.hpds.AllConcepts;
import etl.jobs.jobproperties.JobProperties;
import etl.jobs.mappings.PatientMapping;

public class GenericGlobalConceptsGenerator extends BDCJob {

	private static String STUDY_ACCESSION = "";
	private static String CONSENT = "";
	private static String CONSENT_NAME = "";
	private static String CONSENT_ID = "";
	

	public static void main(String[] args) {
		try {
			setVariables(args, buildProperties(args));
			setLocalVariables(args, buildProperties(args));

		} catch (Exception e) {
			System.err.println("Error processing variables");
			System.err.println(e);
			e.printStackTrace();
		}
		
		try {
			execute();
		} catch (Exception e) {
			System.err.println(e);
			e.printStackTrace();
		}
	}

	private static void execute() throws Exception {

		List<PatientMapping> patientMappings = PatientMapping.readPatientMappingFile(PATIENT_MAPPING_FILE);


		Set<AllConcepts> records = new TreeSet<>( new Comparator<AllConcepts>() {

			@Override
			public int compare(AllConcepts o1, AllConcepts o2) {
				if(o1 == null || o2 == null) return -1;
				
				int conceptpath = o1.getConceptPath().compareTo(o2.getConceptPath());
				
				if(conceptpath != 0) {
					return conceptpath;
				}
				
				int patientNum = o1.getPatientNum().compareTo(o2.getPatientNum());
				
				if(patientNum != 0) {
					return patientNum;
				}
				
				int tvalChar = o1.getTvalChar().compareTo(o2.getTvalChar());
				
				if(tvalChar != 0) {
					return tvalChar;
				}
				
				return(o1.getNvalNum().compareTo(o2.getNvalNum()));
				
										
			}
			
		} ); 
		
		records.addAll(generateGlobalVariables(patientMappings));
		
		try(BufferedWriter buffer = Files.newBufferedWriter(Paths.get(WRITE_DIR + TRIAL_ID + "_GlobalVars.csv"), StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING)) {
			for(AllConcepts ac: records) {
				buffer.write(ac.toCSV());
				buffer.flush();
			}
		}
		
		
	}

	private static Collection<? extends AllConcepts> generateGlobalVariables(List<PatientMapping> patientMappings) {
		Set<AllConcepts> globalVars = new HashSet<>();
		
		globalVars.addAll(generateConsents(patientMappings));
		globalVars.addAll(generateStudyConsents(patientMappings));
		globalVars.addAll(generateStudies(patientMappings));
		globalVars.addAll(generateTopmedSubjectId(patientMappings));

		return globalVars;
	}

	private static Collection<? extends AllConcepts> generateStudies(List<PatientMapping> patientMappings) {
		List<AllConcepts> studies = new ArrayList<>();
		for(PatientMapping pm: patientMappings) {
			AllConcepts ac = new AllConcepts();
			ac.setPatientNum(pm.getPatientNum());
			ac.setConceptPath(PATH_SEPARATOR + "_studies" + PATH_SEPARATOR + ROOT_NODE + PATH_SEPARATOR );
		    ac.setTvalChar("TRUE");
		    ac.setNvalNum("");
		    ac.setStartDate("0");
		    
		    studies.add(ac);;
		}
	
		return studies;
	}
	
	private static Collection<? extends AllConcepts> generateTopmedSubjectId(List<PatientMapping> patientMappings) {
		List<AllConcepts> studies = new ArrayList<>();
		for(PatientMapping pm: patientMappings) {
			AllConcepts ac = new AllConcepts();
			ac.setPatientNum(pm.getPatientNum());
			ac.setConceptPath(PATH_SEPARATOR + "_Topmed Study Accession with Subject ID" + PATH_SEPARATOR + STUDY_ACCESSION + "_" + pm.getSourceId() + PATH_SEPARATOR );
		    ac.setTvalChar("TRUE");
		    ac.setNvalNum("");
		    ac.setStartDate("0");
		    
		    studies.add(ac);;
		}
	
		return studies;
	}
	private static Collection<? extends AllConcepts> generateStudyConsents(List<PatientMapping> patientMappings) {
		List<AllConcepts> studyConsents = new ArrayList<>();
		for(PatientMapping pm: patientMappings) {
			AllConcepts ac = new AllConcepts();
			ac.setPatientNum(pm.getPatientNum());
			ac.setConceptPath(PATH_SEPARATOR + "_studies_consents" + PATH_SEPARATOR + STUDY_ACCESSION + PATH_SEPARATOR + CONSENT_ID 
					+ PATH_SEPARATOR);
		    ac.setTvalChar("TRUE");
		    ac.setNvalNum("");
		    ac.setStartDate("0");
		    
		    studyConsents.add(ac);
		    
			AllConcepts ac2 = new AllConcepts();
			ac2.setPatientNum(pm.getPatientNum());
		    ac2.setTvalChar("TRUE");
		    ac2.setNvalNum("");
		    ac2.setStartDate("0");
		    
		    ac2.setConceptPath(PATH_SEPARATOR + "_studies_consents" + PATH_SEPARATOR + STUDY_ACCESSION + PATH_SEPARATOR);
		    
		    studyConsents.add(ac2);
		    
			AllConcepts ac3 = new AllConcepts();
			ac3.setPatientNum(pm.getPatientNum());
		    ac3.setTvalChar("TRUE");
		    ac3.setNvalNum("");
		    ac3.setStartDate("0");
		    
			ac3.setConceptPath(PATH_SEPARATOR + "_studies_consents" + PATH_SEPARATOR);
		    
		    studyConsents.add(ac3);
		}
	
		return studyConsents;
	}

	private static List<AllConcepts> generateConsents(List<PatientMapping> patientMappings) {
		List<AllConcepts> consents = new ArrayList<>();
		for(PatientMapping pm: patientMappings) {
			AllConcepts ac = new AllConcepts();
			ac.setPatientNum(pm.getPatientNum());
			ac.setConceptPath(PATH_SEPARATOR + "_consents" + PATH_SEPARATOR );
		    ac.setTvalChar(STUDY_ACCESSION + ".c1");
		    ac.setNvalNum("");
		    ac.setStartDate("0");
		    consents.add(ac);
		}
		
		return consents;
	}

	private static void setLocalVariables(String[] args, JobProperties properties) throws Exception {
		/*if(properties != null) {
			if(properties.contains("usepatientmapping")) {
				if(new String(StringUtils.substring(properties.getProperty("usepatientmapping"),0,1)).equalsIgnoreCase("Y")){
					USE_PATIENT_MAPPING = true;
				}
			}
			if(properties.contains("patientcol")) {
				
				PATIENT_COL = new Integer(properties.get("patientcol").toString());
				
				
			}
		}	*/
		for(String arg: args) {
			if(arg.equalsIgnoreCase("-consentname")) {
				CONSENT_NAME = checkPassedArgs(arg, args);;
			}
			if(arg.equalsIgnoreCase("-consentid")) {
				CONSENT_ID = checkPassedArgs(arg, args);;
			}
			if(arg.equalsIgnoreCase("-accession")) {
				STUDY_ACCESSION = checkPassedArgs(arg, args);;
			}
		}
		
	}

}
