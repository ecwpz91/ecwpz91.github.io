---
layout: post
---

# Developing a Servlet

## Problem

You want to develop a web page that includes dynamic content using the Java
programming language.

## Solution

Create a Java servlet class, and compile it to run within a Java servlet
container.

Servlets are the core classes in any web application, the only classes that
either perform the work of responding to requests or delegate that work to some
other aspect of the application.

You should begin by creating a new, empty Servlet that extends HttpServlet:



**[NOTE]** A class that is not in a named package is in an unnamed package. T
hus the full class name is "Main".

## How It Works

In the Java Platform, Enterprise Edition, a _Servlet_ is what recieves and
responds to requests from the end user. The Java EE API specification defines a
Servlet as follows:

> "A Servlet is a small Java program that runs within a Web server. Servlets
receive and respond to requests from Web clients, usually across HTTP, the
HyperText Transfer Protocol." Click [here](http://bit.ly/2a7mkFK) for further
information.

For responding to HTTP-specific requests, javax.servlet.http.HttpServlet
extends GenericServlet and implements the service method to accept only HTTP
requests.

## References

1. Williams, Nicholas S. (2014). Professional Java for Web Applications. Wiley.

2. Juneau, Josh (2013). Java EE 7 Recipes: A Porblem-Solution Approach. Apress.
