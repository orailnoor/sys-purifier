#pragma once
#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct _MARGINS {
  int cxLeftWidth;
  int cxRightWidth;
  int cyTopHeight;
  int cyBottomHeight;
} MARGINS, *PMARGINS;

#ifdef __cplusplus
}
#endif
