CREATE OR REPLACE PACKAGE XXCSM002A13C AS

/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A13C(spec)
 * Description      : ¤ivæXg(nñ_{PÊ)oÍ
 * MD.050           : ¤ivæXg(nñ_{PÊ)oÍ MD050_CSM_002_A13
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  init                yúzA-1
 *
 *  do_check            y`FbNzA-2~A-3
 *
 *  deal_item_data      y¤iPÊÌzA-4~A-6
 *
 *  deal_group4_data    y¤iQPÊÌzA-7~A-9
 *
 *  deal_group1_data    y¤iæªPÊÌzA-10~A-12
 *
 *  deal_sum_data       y¤ivPÊÌzA-13~A-15
 *
 *  deal_down_data      y¤iløPÊÌzA-16~A-17
 *
 *  deal_kyoten_data    y_PÊÌzA-18~A-20
 *
 *  deal_all_data       y_XgPÊÌzA-2~A-20
 *
 *  get_col_data        yeÚf[^Ìæ¾zA-21
 *     
 *  deal_csv_data        yoÍ{fBîñÌæ¾zA-21
 *  
 *  write_csv_file      yoÍzA-22
 *  
 *  submain             yÀzA-1~A-23
 *
 *  main                yRJgÀst@Co^vV[WzA-1~A-23
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/20    1.0   ohshikyo        VKì¬
 *  2012/12/19    1.1   SCSK K.Taniguchi [E_{Ò®_09949] V´¿IðÂ\Î
 *
 *****************************************************************************************/
--
  --RJgÀst@Co^vV[W
  PROCEDURE main(
      errbuf           OUT    NOCOPY VARCHAR2,         --   G[bZ[W
      retcode          OUT    NOCOPY VARCHAR2,         --   G[R[h
      iv_taisyo_ym     IN     VARCHAR2,                --   ÎÛNx
      iv_kyoten_cd     IN     VARCHAR2,                --   _R[h
      iv_cost_kind     IN     VARCHAR2,                --   ´¿íÊ
--//+UPD START E_{Ò®_09949 K.Taniguchi
--      iv_kyoten_kaisou IN     VARCHAR2                 --   Kw
      iv_kyoten_kaisou IN     VARCHAR2,                --   Kw
      iv_new_old_cost_class
                       IN     VARCHAR2                 --   V´¿æª
--//+UPD END E_{Ò®_09949 K.Taniguchi
  );
END XXCSM002A13C;
/
