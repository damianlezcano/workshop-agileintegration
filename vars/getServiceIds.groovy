#!/usr/bin/env groovy

def call(uri) {
    def cmd = [ 'bash', '-c', "curl -k ${uri}".toString()]
    def text = cmd.execute().text
    def list = new XmlSlurper().parseText(text)
    return list.service*.id
}