/*
 * base class for the applications running on controller
 */

#ifndef _MY_APP_H__
#define _MY_APP_H__

#include <string>

class controller;

using namespace std;

class MyApp
{
public:
  //member methods
  MyApp(controller *pController)
    : m_pController(pController)
  {};
  
  virtual ~MyApp(){};
  
  virtual void init() = 0;
  
  virtual void exec() = 0;
  
  virtual void quit() = 0;

public:
  //member variables
  controller *m_pController;

  string m_cpu_str;
};

#endif // _MY_APP_H__
