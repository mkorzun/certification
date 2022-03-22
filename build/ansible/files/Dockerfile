ARG tag_buildimage
ARG tag_stageimage
ARG buildimage_registry
ARG stageimage_registry
FROM kmi8652/mybuildimage:$tag_buildimage AS build
RUN git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git /tmp/boxfuse-sample-java-war-hello-war-hello
RUN mvn -f /tmp/boxfuse-sample-java-war-hello-war-hello/pom.xml clean package
FROM kmi8652/mystageimage:$tag_stageimage
COPY --from=build /tmp/boxfuse-sample-java-war-hello-war-hello/target/hello-*.war /opt/tomcat/webapps/
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
