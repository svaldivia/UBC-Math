<%@ page import="blackboard.platform.gradebook2.impl.*"%>
<%@ page import="blackboard.platform.context.*"%>
<%@ page import="blackboard.base.*"%>
<%@ page import="blackboard.persist.*"%>
<%@ page import="blackboard.platform.gradebook2.*"%>
<%@ page import="blackboard.data.course.*"%>
<%@ page import="blackboard.data.*"%>
<%@ page import="blackboard.persist.course.*"%>
<%@ page import="java.util.*"%>

<!-- Custom Classes -->
<%@ page import="courseClasses.*"%>

<!-- User Data -->
<%@ page import="blackboard.data.user.*"%>


<!-- Declarations -->
<%!
	String lookText(char[] input){
		String text = "";
		char current = input[0];
		int i = 0;
		
		while(current != '_'){
			text += String.valueOf(current);
			i++;
			current = input[i];
		}
		return text;
	}
%>


<%	
	//Get Student Name
	//----------------
	//initializes context
	
	ContextManagerFactory.getInstance().setContext(request);
	//Session User
	User sessionUser = ContextManagerFactory.getInstance().getContext().getUser();

	//retrieves the users first name, you can get any parameter from blackboard.data.user.User from the getUser() method.
	String firstName = sessionUser.getGivenName();
	Id sessionUserId = sessionUser.getId();
	
	
	//Set up for gradebook extraction
	//-------------------------------
	//specify the course name for which to extract the grades
	String courseIdParameter = request.getParameter("course_id");
	Id courseId = Id.generateId(Course.DATA_TYPE, courseIdParameter);
			
	//use the GradebookManager to get the gradebook data
	GradebookManager gm = GradebookManagerFactory.getInstanceWithoutSecurityCheck();
	BookData bookData = gm.getBookData(new BookDataRequest(courseId));
	List<GradableItem> lgm = gm.getGradebookItems(courseId);
	
	//it is necessary to execute these two methods to obtain calculated scores and extended grade data
	bookData.addParentReferences();
	bookData.runCumulativeGrading();
	CourseMembership cm = CourseMembershipDbLoader.Default.getInstance().loadByCourseAndUserId(courseId, sessionUserId);
%>

<!-- These lines of code are fine ^^^^^^ -->

<!DOCTYPE html>
<html>
<head>

</head>
<body>

<h1>Grade Extractor</h1><br />
<hr>
<h2>
	Hello, <% out.println(firstName);%> !
</h2>

<%
		
		//Array that contains all topics
		ArrayList<Topic> topics = new ArrayList<Topic>(); 
		//Array that constains all diadnostic test
		ArrayList<Test> diagnostic = new ArrayList<Test>();					

		//Iterate through student grades
		for (int x = 0; x < lgm.size(); x++){
 				GradableItem gi = (GradableItem) lgm.get(x);
 				//Prints type of score
 				double grade = 0;
 				
 				//Define grade
 				try{
 					GradeWithAttemptScore gwas2 = bookData.get(cm.getId(), gi.getId());
 					grade = gwas2.getScoreValue();
 				}catch(NullPointerException e){
 					//No grades assigned
 					grade = 0;
 				}
 				
 				
 				//TEST
 				
 				//Test title syntax: Type_Type#_Section_Section#   NOTE: It can also be a diagnostic test
 				
 				String test = gi.getTitle();  						//Title of test
 				String delims = "[_]+";
 				String[] testTitle = test.split(delims); 			//Have an array of all the titles of the test
 				
 				//Treat topics and diagnostics differently
 				if( testTitle[0].compareTo("Topic") == 0){
 					//TOPIC------
 					
 					String topicTitle = testTitle[0]+" "+testTitle[1];
 					Topic temp = new Topic();
 					boolean topicFound = false;
 					int indexFound = -1;
 					
 					out.println("Entra correctamente <br />");
 					out.println("Title: "+test+"<br />");
 					out.println("Topic Title: "+topicTitle+"<br />");
 					out.println("Array size: "+topics.size()+"<br />");
 					
 					//Check if topic exits
 					if(topics.size() > 0){												//Search for topic in the existing array
 						for(int i=0; i< topics.size(); i++){
 							if (topicTitle.compareTo(topics.get(i).getName()) == 0){
 								// Save found index, create a temporary topic
 								// and erase the topic in the list
 								indexFound = i;
 								temp = topics.get(i);
 								topics.remove(i);
 								topicFound = true;
 							}
 						}
 						
 					}
 					if (topicFound = false){		//Add topic
 						temp = new Topic(topicTitle);
 						}
 				out.println("Topic Added"+"<br />");
 					
 				 	//Test to be added
 					Test newTest = new Test("",grade);
 					newTest.setGrade(grade);
 					
 					//NOTE: We assume that user inputs everything in the correct format
 					
 					out.println("Array length: "+testTitle.length+"<br />");
 					
 					//Topic Test
 					if(testTitle.length <= 2){							//!!!!! SI ESTO NO FUNCIONA HABRA QUE CONTAR :S
 						newTest.setName("Topic Test " + testTitle[1]);
 					// CHECK: If input topic does not have a number
 						out.println("Entra bien <br />");
 						out.println("Test name: "+newTest.getName());
 					}else if(testTitle.length > 2){
 						//Section Test
 						newTest.setName("Section Test "+ testTitle[3]);
 					}
 					 
 					//Add test to topic
 					temp.add(newTest); 
 					out.println("Test added <br />");
 					out.println("indexFound: "+indexFound+"<br />");
 					out.println("Topic name: "+temp.getName()+"<br />");
 					
 					//Add to topic array
 					if(indexFound != -1){
 						//Insert into existing topic
 						topics.add(indexFound, temp);   //CHECK!!!!
 					}else{
 						//Add new topic to array
 						topics.add(temp);
 					}
 					
 				}else if(testTitle[0].compareTo("Diagnostic") == 0){
 					//DIAGNOSTIC
 					
 					//Create diagnostic test
 					Test newDiag = new Test(testTitle[0]+" "+testTitle[1], grade);
 					
 					//Add to array
 					diagnostic.add(newDiag);
 				}
		}
%>

<h2>Grades</h2>
<hr>

<!-- Testear desde aca  -->

<%
		if(diagnostic.size() > 0){
			//Print Diagnostic Tests
			out.println("<h3>Diagnostic Tests</h3>");
			for(int i=0; i<diagnostic.size(); i++){
				out.println(diagnostic.get(i).getName()+": "+diagnostic.get(i).getGrade()+"<br />");
			}
		}

		if(topics.size() > 0){
			//Print Topics
			for(int i=0; i < topics.size(); i++){
				Topic current = topics.get(i);
				//Title
				out.println("<h3>"+current.getName()+"</h3>");
				for(int k=0; k < current.getSectionLength(); k++){
					out.println(current.getSection(k).getName()+": "+ current.getSection(k).getGrade()+"<br />");
				}
				//Avg Topic Grade
				out.println("Average Topic Grade: "+ current.avgGrade()+"<br />");
				out.println("size: "+ topics.size()+"<br />");
				out.println("i: "+ i);
			}
		}
		
		if(topics.size() == 0 && diagnostic.size() == 0){
			out.println("<h3>ERROR: Nothing to show</h3>");					//Error handler
		}
%>


</body>
</html>






