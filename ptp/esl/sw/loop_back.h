/*
 * loop back test
 */

#ifndef _LOOP_BACK_H__
#define _LOOP_BACK_H__

#include "MyApp.h"

class loop_back: public MyApp
{
  //member methods
  public:
    loop_back(controller *pController);
  
    virtual ~loop_back();
  
    virtual void init();
  
    virtual void exec();
  
    virtual void quit();

    void register_test();

    void frame_test();

  //member variables
  //protected:
};

#endif // _LOOP_BACK_H__

