from lxml import html
import requests
import re
import time
import csv
from selenium import webdriver

def addLeadingZeroes(phv):
    leng = len(phv)
    
    maxleng = len('00082624')
    
    while maxleng > leng:
        phv = '0' + phv
        leng += 1
        
    return 'phv' + phv

#'https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/variable.cgi?study_id=phs000209.v13.p3&phv=82624&phd=1712&pha=&pht=1116&phvf=1&phdf=&phaf=&phtf=3&dssp=1&consent=&temp=1'
def getNextNode(browser,url):
    browser.get(url)
    time.sleep(sleep_time)
    #variables = browser.find_elements_by_xpath('.//*[@id="associatedVariables"]/div')[0]
    #print("variables" + variables)
    #print('\\' + variables.text + '\\')
    inner_nodes = browser.find_elements_by_xpath('.//*[@id="associatedVariables"]//li[contains(@style,"page-foldericon")]/div')
    value_nodes = browser.find_elements_by_xpath('.//div[@id="associatedVariables"]//a[contains(@onclick,"variable.cgi")]')

    if(len(value_nodes) > 0):
        scrapeValueNodes(browser,value_nodes)
    
    if(len(inner_nodes) > 0):
        found_phvf = dict()
        
        for inner_node in inner_nodes:
            #div_node = inner_node.find_element_by_xpath('.//*[@class="groupNode"]')
            collectPhvf(inner_node, found_phvf)
            #phvf = inner_node.get_attribute("onclick")
            #phvf = phvf.replace("setState('phvf', ","")
            #phvf = re.sub(r'\).*','',phvf)
            #print(phvf)
            #url = 'https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/variable.cgi?study_id=' + study_id + '&phv=' + phv
            #nexturl = url + '&phvf=' + phvf
            #print(nexturl)
            #browser.get(nexturl)
            
            #getNextNode(browser,nexturl,pathWithVariable)
                
        for node, phvf in found_phvf.items():
            url = 'https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/variable.cgi?study_id=' + study_id + '&phv=' + phv
            nexturl = url + '&phvf=' + phvf
            getNextNode(browser,nexturl)
            browser.get(nexturl)
                    
def collectPhvf(inner_node, tdict):
    phvf = inner_node.get_attribute("onclick")
    phvf = phvf.replace("setState('phvf', ","")
    phvf = re.sub(r'\).*','',phvf)
    tdict[inner_node.text] = phvf
    
    return dict
    
def scrapeValueNodes(browser,value_nodes):
    try:
        with open('./hierarchies/' + study_id + '.hierarchy.csv','a') as csv_file:
            writer = csv.writer(csv_file)
            time.sleep(sleep_time)  
            #for node in value_nodes:

            root_node = browser.find_element_by_xpath('.//*[@class="studyNode"]').text
            
            subpaths = browser.find_elements_by_xpath('.//div[@id="associatedVariables"]/div/ul/ul//div[@class="groupNode"]')
            
            anchors = browser.find_elements_by_xpath('.//div[@id="associatedVariables"]//a[@href="#"]')
            
            for anchor in anchors:
                path = ''

                row = []

                pvf = anchor.get_attribute("onclick")
                
                pvf = pvf.replace("javascript:getPage(this, 'variable.cgi', ", '')
                
                pvf = pvf.replace(");return true;",'')
                                
                path = path + '\\' + root_node + '\\'

                for spath in subpaths:
                    
                    path = path + spath.text + '\\'
        
                #concept_dict[node.text] = path
                
                row.append(path)
                
                row.append(addLeadingZeroes(pvf))
                
                row.append(anchor.text)

                writer.writerows([row])
                    
    except (Exception):
        pass

sleep_time = 1
 #'phs000280.v5.p1': '294463',
    #'phs000285.v3.p2': '112394',
    #'phs000284.v2.p1': '124333',
    #'phs000287.v6.p1': '98769',
    #'phs000179.v6.p2': '159559',
    #'phs000007.v30.p11': '159553'
    #'phs000784.v2.p1': '217804',
    #'phs000741.v2.p1': '202093',
    #'phs000810.v1.p1': '226255',
    #'phs001013.v3.p2': '259387',
    #'phs000286.v6.p2': '124566',
    #'phs000289.v2.p1': '121844',
    #'phs000209.v13.p3': '163181',
    #'phs001024.v3.p1': '253775',
    #'phs000847.v2.p1': '225463',
    #'phs000921.v3.p1.c2': '347787',
    #'phs000914.v1.p1': '258686',
    #'phs000997.v3.p2': '265931',
    #'phs000200.v11.p3': '161362',      
study_ids = { 
    #'phs000956.v3.p1':'252986',
    #'phs001143.v2.p1':'375336',
    #'phs001143.v2.p1':'375336',
    #'phs000988.v3.p1':'258652',
    #'phs001412.v1.p1':'310021',
    #'phs001180.v1.p1':'320636',
    #'phs001218.v1.p1':'369290',
    #'phs001238.v2.p1':'277518',
    #'phs001062.v3.p2':'258883',
    #'phs001032.v4.p2':'253683'
    #'phs001040.v3.p1':'265849',
    #'phs000946.v3.p1':'252863',
    #'phs000921.v3.p1':'347787',
    #'phs000820.v1.p1':'219058'
    #'phs001074.v1.p1':'259658'
    'phs001001.v1.p1':'354577'
 }

for study_id, phv in study_ids.items():            

    url = 'https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/variable.cgi?study_id=' + study_id + '&phv=' + phv
    
    browser = webdriver.Chrome()
    browser.get(url)
    
    time.sleep(sleep_time)
    
    #avarselem = browser.find_elements_by_xpath("//div[@id=associatedVariables]/div/ul")
    
    
    groupNodes = browser.find_elements_by_xpath('.//*[@class="groupNode"]')
     
    nodes_with_phvf = dict()
    
    for groupNode in groupNodes:
        
        phvf = groupNode.get_attribute("onclick")
        phvf = phvf.replace("setState('phvf', ","")
        phvf = re.sub(r'\).*','',phvf)
        
        nodes_with_phvf[groupNode.text] = phvf
        
    for node, phvf in nodes_with_phvf.items():
        nexturl = url + '&phvf=' + phvf
        getNextNode(browser,nexturl)
        #browser.get(nexturl)

print('script done')
