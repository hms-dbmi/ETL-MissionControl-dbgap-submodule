package etl.jobs.csv.bdc;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectWriter;
import com.opencsv.CSVReader;

import etl.metadata.MetadataFactory;
import etl.metadata.bdc.BDCMetadata;
import etl.metadata.bdc.BDCMetadataElements;

public class UpdateCountsInJsonMetadata extends BDCJob {

	public static void main(String[] args) {
		try {

			setVariables(args, buildProperties(args));
						
		} catch (Exception e) {
			
			System.err.println("Error processing variables");
			
			System.err.println(e);
			
		}	
		
		try {
			
			execute();
			
		} catch (IOException e) {
			
			System.err.println(e);
			
		}
	}

	private static void execute() throws IOException {
		
		Map<String, Set<String>> phenoCounts = readPhenoCounts("phenoCounts.csv");
		
		Map<String, String> genoCounts = readCounts(1,"genoCounts.csv");
		
		BDCMetadata meta = (BDCMetadata) MetadataFactory.readMetadata("BDC", new File(DATA_DIR + "metadata.json"));
		
		for(BDCMetadataElements element: meta.bio_data_catalyst) {
			updatePhenoCount(element,phenoCounts);
			updateGenoCount(element,genoCounts);
		}
		
		ObjectMapper mapper = new ObjectMapper();

		ObjectWriter ow = mapper.writer().withDefaultPrettyPrinter();
		
		validate(meta);
		
		try(BufferedWriter buffer = Files.newBufferedWriter(Paths.get(WRITE_DIR + "metadata.json") , StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING)) {
			
			buffer.write(ow.writeValueAsString(meta));
			
		}
	}

	private static Map<String, Set<String>> readPhenoCounts(String dataFile) throws IOException {
		Map<String, Set<String>> counts = new HashMap<>();
		
		try(BufferedReader buffer = Files.newBufferedReader(Paths.get(DATA_DIR + dataFile))) {
			
			CSVReader reader = new CSVReader(buffer);
			
			reader.readNext();
			String[] line;
			while((line = reader.readNext()) != null) {
				if(line.length == -1) continue;
				if(!line[line.length - 1].isEmpty()) {
					if(counts.containsKey(line[line.length - 1]) ) {
						counts.get(line[line.length - 1]).add(line[0]);
					} else {
						Set<String> set = new HashSet<>();
						set.add(line[0]);
						counts.put(line[line.length - 1], set );
					}
				}
				if(!line[line.length - 2].isEmpty()) {
	
					if(counts.containsKey(line[line.length - 2]) ) {
						counts.get(line[line.length - 2]).add(line[0]);
					} else {
						Set<String> set = new HashSet<>();
						set.add(line[0]);
						counts.put(line[line.length - 2], set );
					}
				}
			}
		}
		
		return counts;
	}

	private static void validate(BDCMetadata meta) {
		List<BDCMetadataElements> posCountMeta = new ArrayList<>();
		for(BDCMetadataElements element: meta.bio_data_catalyst) {
			if(element.raw_clinical_sample_size != -1 ) {
				if(!element.clinical_sample_size.equals(element.raw_clinical_sample_size)) {
					System.err.println(element.abbreviated_name + " - " + element.study_identifier + " - " + element.consent_group_code + " - Clinical Counts are off:");
					System.err.println("raw count = " + element.raw_clinical_sample_size);
					System.err.println("manual count = " + element.clinical_sample_size);
	
				}
			}
			if(element.raw_genetic_sample_size != -1) {
				if(!element.genetic_sample_size.equals(element.raw_genetic_sample_size)) {
					System.err.println(element.abbreviated_name + " - " + element.study_identifier + " - " + element.consent_group_code + " - Genomic Counts are off:");
					System.err.println("raw count = " + element.raw_genetic_sample_size);
					System.err.println("manual count = " + element.genetic_sample_size);
				}
			}
			if(element.clinical_sample_size != -1 ) {
				posCountMeta.add(element);
			}
		}
		meta.bio_data_catalyst = posCountMeta;
	}

	private static void updatePhenoCount(BDCMetadataElements element, Map<String, Set<String>> phenoCounts) {
		
		if(phenoCounts.containsKey(element.study_identifier + "." + element.consent_group_code)) {
			element.clinical_sample_size = phenoCounts.get(element.study_identifier + "." + element.consent_group_code).size();
			element.clinical_variable_count = element.raw_clinical_variable_count;
		} else {
			
			System.err.println("missing pheno counts for " + element.study_identifier);
		}
		
	}

	private static void updateGenoCount(BDCMetadataElements element, Map<String, String> genoCounts) {
		
		if(genoCounts.containsKey(element.study_identifier + "." + element.consent_group_code)) {
			element.genetic_sample_size = new Integer(genoCounts.get(element.study_identifier + "." + element.consent_group_code));
		} else {
			if(element.consent_group_code.equals("c0")) { 
				System.out.println("ignoring c0 for genomic counts for " + element.study_identifier + "." + element.consent_group_code);
			} else {
				System.err.println("missing genomic counts for " + element.study_identifier + "." + element.consent_group_code);
			}
		}
		
	}
	
	private static Map<String, String> readCounts(int colIdx, String dataFile) throws IOException {
		try(BufferedReader buffer = Files.newBufferedReader(Paths.get(DATA_DIR + dataFile))) {
			
			
			List<String[]> list = new CSVReader(buffer).readAll();
			
			Map<String,String> counts = new HashMap<>();
			
			for(String[] x: list) {
				counts.put(x[0], x[colIdx]);
			}
			return counts;
		}
		
	}

}
