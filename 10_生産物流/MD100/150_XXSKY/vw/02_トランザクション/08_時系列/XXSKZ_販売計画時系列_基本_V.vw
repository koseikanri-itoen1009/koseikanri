/*************************************************************************
 * 
 * View  Name      : XXSKZ_Ìvænñ_î{_V
 * Description     : XXSKZ_Ìvænñ_î{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/26    1.0   SCSK M.Nagai ñì¬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_Ìvænñ_î{_V
(
 Nx
,¢ã
,_R[h
,_¼
,¤iæª
,¤iæª¼
,iÚæª
,iÚæª¼
,QR[h
,iÚR[h
,iÚ¼
,iÚªÌ
,NÔvP[X
,NÔvo
,NÔvàz
,NÔ|¦
,ÌvæP[X_T
,Ìvæo_T
,Ìvæàz_T
,Ìvæ|¦_T
,ÌvæP[X_U
,Ìvæo_U
,Ìvæàz_U
,Ìvæ|¦_U
,ÌvæP[X_V
,Ìvæo_V
,Ìvæàz_V
,Ìvæ|¦_V
,ÌvæP[X_W
,Ìvæo_W
,Ìvæàz_W
,Ìvæ|¦_W
,ÌvæP[X_X
,Ìvæo_X
,Ìvæàz_X
,Ìvæ|¦_X
,ÌvæP[X_PO
,Ìvæo_PO
,Ìvæàz_PO
,Ìvæ|¦_PO
,ÌvæP[X_PP
,Ìvæo_PP
,Ìvæàz_PP
,Ìvæ|¦_PP
,ÌvæP[X_PQ
,Ìvæo_PQ
,Ìvæàz_PQ
,Ìvæ|¦_PQ
,ÌvæP[X_P
,Ìvæo_P
,Ìvæàz_P
,Ìvæ|¦_P
,ÌvæP[X_Q
,Ìvæo_Q
,Ìvæàz_Q
,Ìvæ|¦_Q
,ÌvæP[X_R
,Ìvæo_R
,Ìvæàz_R
,Ìvæ|¦_R
,ÌvæP[X_S
,Ìvæo_S
,Ìvæàz_S
,Ìvæ|¦_S
)
AS
SELECT
        SMFC.year                                                     year                --Nx
       ,SMFC.generation                                               generation          --¢ã
       ,SMFC.hs_branch                                                hs_branch           --_R[h
       ,BRCH.party_name                                               hs_branch_name      --_¼
       ,PRODC.prod_class_code                                         prod_class_code     --¤iæª
       ,PRODC.prod_class_name                                         prod_class_name     --¤iæª¼
       ,ITEMC.item_class_code                                         item_class_code     --iÚæª
       ,ITEMC.item_class_name                                         item_class_name     --iÚæª¼
       ,CROWD.crowd_code                                              crowd_code          --QR[h
       ,ITEM.item_no                                                  item_code           --iÚR[h
       ,ITEM.item_name                                                item_name           --iÚ¼
       ,ITEM.item_short_name                                          item_s_name         --iÚªÌ
        --=====================
        -- NÔ
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.sum_year_qty / ITEM.num_of_cases ), 0 )      sum_year_cs_qty     --NÔvP[X
--       ,NVL( CEIL( SMFC.sum_year_qty / ITEM.num_of_cases ), 0 )      sum_year_cs_qty     --NÔvP[X
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.sum_year_qty / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      sum_year_cs_qty     --NÔvP[X
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.sum_year_qty , 0 )                                  sum_year_qty        --NÔvo
       ,NVL( SMFC.sum_year_amt , 0 )                                  sum_year_amt        --NÔvàz
        --|¦  p[ZgPÊ(­_æRÊÈºlÌÜü)Å\¦
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.sum_year_qty, 0 ) <> 0 THEN  --[èÎô
                  -- |¦  Ìàzè¿àz(è¿~Ê)
                  NVL( ROUND( ( SMFC.sum_year_amt / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.sum_year_qty ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           sum_year_rate       --NÔ|¦
        --=====================
        --T
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_5th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_5th       --ÌvæP[X_T
--       ,NVL( CEIL( SMFC.fc_qty_5th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_5th       --ÌvæP[X_T
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_5th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_5th       --ÌvæP[X_T
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_5th   , 0 )                                  fc_qty_5th          --Ìvæo_T
       ,NVL( SMFC.fc_amt_5th   , 0 )                                  fc_amt_5th          --Ìvæàz_T
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_5th , 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_5th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_5th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_5th         --Ìvæ|¦_T
        --=====================
        --U
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_6th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_6th       --ÌvæP[X_U
--       ,NVL( CEIL( SMFC.fc_qty_6th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_6th       --ÌvæP[X_U
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_6th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_6th       --ÌvæP[X_U
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_6th   , 0 )                                  fc_qty_6th          --Ìvæo_U
       ,NVL( SMFC.fc_amt_6th   , 0 )                                  fc_amt_6th          --Ìvæàz_U
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_6th , 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_6th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_6th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_6th         --Ìvæ|¦_U
        --=====================
        --V
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_7th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_7th       --ÌvæP[X_V
--       ,NVL( CEIL( SMFC.fc_qty_7th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_7th       --ÌvæP[X_V
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_7th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_7th       --ÌvæP[X_V
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_7th   , 0 )                                  fc_qty_7th          --Ìvæo_V
       ,NVL( SMFC.fc_amt_7th   , 0 )                                  fc_amt_7th          --Ìvæàz_V
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_7th , 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_7th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_7th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_7th         --Ìvæ|¦_V
        --=====================
        --W
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_8th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_8th       --ÌvæP[X_W
--       ,NVL( CEIL( SMFC.fc_qty_8th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_8th       --ÌvæP[X_W
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_8th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_8th       --ÌvæP[X_W
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_8th   , 0 )                                  fc_qty_8th          --Ìvæo_W
       ,NVL( SMFC.fc_amt_8th   , 0 )                                  fc_amt_8th          --Ìvæàz_W
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_8th , 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_8th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_8th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_8th         --Ìvæ|¦_W
        --=====================
        --X
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_9th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_9th       --ÌvæP[X_X
--       ,NVL( CEIL( SMFC.fc_qty_9th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_9th       --ÌvæP[X_X
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_9th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_9th       --ÌvæP[X_X
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_9th   , 0 )                                  fc_qty_9th          --Ìvæo_X
       ,NVL( SMFC.fc_amt_9th   , 0 )                                  fc_amt_9th          --Ìvæàz_X
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_9th , 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_9th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_9th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_9th         --Ìvæ|¦_X
        --=====================
        --PO
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_10th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_10th      --ÌvæP[X_PO
--       ,NVL( CEIL( SMFC.fc_qty_10th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_10th      --ÌvæP[X_PO
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_10th  / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_10th      --ÌvæP[X_PO
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_10th  , 0 )                                  fc_qty_10th         --Ìvæo_PO
       ,NVL( SMFC.fc_amt_10th  , 0 )                                  fc_amt_10th         --Ìvæàz_PO
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_10th, 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_10th / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_10th ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_10th        --Ìvæ|¦_PO
        --=====================
        --PP
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_11th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_11th      --ÌvæP[X_PP
--       ,NVL( CEIL( SMFC.fc_qty_11th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_11th      --ÌvæP[X_PP
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_11th  / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_11th      --ÌvæP[X_PP
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_11th  , 0 )                                  fc_qty_11th         --Ìvæo_PP
       ,NVL( SMFC.fc_amt_11th  , 0 )                                  fc_amt_11th         --Ìvæàz_PP
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_11th, 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_11th / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_11th ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_11th        --Ìvæ|¦_PP
        --=====================
        --PQ
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_12th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_12th      --ÌvæP[X_PQ
--       ,NVL( CEIL( SMFC.fc_qty_12th  / ITEM.num_of_cases ), 0 )      fc_cs_qty_12th      --ÌvæP[X_PQ
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_12th  / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_12th      --ÌvæP[X_PQ
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_12th  , 0 )                                  fc_qty_12th         --Ìvæo_PQ
       ,NVL( SMFC.fc_amt_12th  , 0 )                                  fc_amt_12th         --Ìvæàz_PQ
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_12th, 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_12th / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_12th ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_12th        --Ìvæ|¦_PQ
        --=====================
        --P
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_1th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_1th       --ÌvæP[X_P
--       ,NVL( CEIL( SMFC.fc_qty_1th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_1th       --ÌvæP[X_P
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_1th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_1th       --ÌvæP[X_P
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_1th   , 0 )                                  fc_qty_1th          --Ìvæo_P
       ,NVL( SMFC.fc_amt_1th   , 0 )                                  fc_amt_1th          --Ìvæàz_P
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_1th , 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_1th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_1th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_1th         --Ìvæ|¦_P
        --=====================
        --Q
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_2th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_2th       --ÌvæP[X_Q
--       ,NVL( CEIL( SMFC.fc_qty_2th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_2th       --ÌvæP[X_Q
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_2th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_2th       --ÌvæP[X_Q
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_2th   , 0 )                                  fc_qty_2th          --Ìvæo_Q
       ,NVL( SMFC.fc_amt_2th   , 0 )                                  fc_amt_2th          --Ìvæàz_Q
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_2th , 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_2th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_2th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_2th         --Ìvæ|¦_Q
        --=====================
        --R
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_3th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_3th       --ÌvæP[X_R
--       ,NVL( CEIL( SMFC.fc_qty_3th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_3th       --ÌvæP[X_R
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_3th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_3th       --ÌvæP[X_R
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_3th   , 0 )                                  fc_qty_3th          --Ìvæo_R
       ,NVL( SMFC.fc_amt_3th   , 0 )                                  fc_amt_3th          --Ìvæàz_R
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_3th , 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_3th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_3th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_3th         --Ìvæ|¦_R
        --=====================
        --S
        --=====================
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 START
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 START
--       ,NVL( TRUNC( SMFC.fc_qty_4th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_4th       --ÌvæP[X_S
--       ,NVL( CEIL( SMFC.fc_qty_4th   / ITEM.num_of_cases ), 0 )      fc_cs_qty_4th       --ÌvæP[X_S
-- MOD DATE:2011/02/01 AUTHOR:OUKOU CONTENT:E_{Ò®_02856 END
       ,NVL( CEIL( SMFC.fc_qty_4th   / DECODE(NVL(ITEMB.attribute11,0),0,null,ITEMB.attribute11) ), 0 )      fc_cs_qty_4th       --ÌvæP[X_S
-- MOD DATE:2011/03/02 AUTHOR:HORIGOME CONTENT:E_{Ò®_02856 END
       ,NVL( SMFC.fc_qty_4th   , 0 )                                  fc_qty_4th          --Ìvæo_S
       ,NVL( SMFC.fc_amt_4th   , 0 )                                  fc_amt_4th          --Ìvæàz_S
       ,CASE WHEN NVL( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_4th , 0 ) <> 0 THEN  --[èÎô
                  NVL( ROUND( ( SMFC.fc_amt_4th  / ( TO_NUMBER( ITEMB.attribute5 ) * SMFC.fc_qty_4th  ) ) * 100, 2 ), 0 )
             ELSE 0
        END                                                           fc_rate_4th         --Ìvæ|¦_S
  FROM
       ( --NA¢ãA_AiÚPÊÅWvµ½ÌvæWvf[^
          SELECT
                  ICD.fiscal_year                                     year                --Nx
                 ,MFDN.attribute5                                     generation          --¢ã
                 -- 2009/05/12 T.Yoshimoto Mod Start {Ô#1469
                 --,MFDN.attribute3                                     hs_branch           --_
                 ,MFDT.attribute5                                     hs_branch           --_
                 -- 2009/05/12 T.Yoshimoto Mod End {Ô#1469
                 ,MFDT.inventory_item_id                              inv_item_id         --iÚID(INViÚID)
                  --NÔ
                 ,SUM( MFDT.current_forecast_quantity )               sum_year_qty        --NÔvÊ
                 ,SUM( TO_NUMBER( MFDT.attribute2 )   )               sum_year_amt        --NÔvàz
                  --T
                 ,SUM( CASE WHEN ICD.period =  1 THEN MFDT.current_forecast_quantity END )  fc_qty_5th     --Ìvæo_T
                 ,SUM( CASE WHEN ICD.period =  1 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_5th     --Ìvæàz_T
                  --U
                 ,SUM( CASE WHEN ICD.period =  2 THEN MFDT.current_forecast_quantity END )  fc_qty_6th     --Ìvæo_U
                 ,SUM( CASE WHEN ICD.period =  2 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_6th     --Ìvæàz_U
                  --V
                 ,SUM( CASE WHEN ICD.period =  3 THEN MFDT.current_forecast_quantity END )  fc_qty_7th     --Ìvæo_V
                 ,SUM( CASE WHEN ICD.period =  3 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_7th     --Ìvæàz_V
                  --W
                 ,SUM( CASE WHEN ICD.period =  4 THEN MFDT.current_forecast_quantity END )  fc_qty_8th     --Ìvæo_W
                 ,SUM( CASE WHEN ICD.period =  4 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_8th     --Ìvæàz_W
                  --X
                 ,SUM( CASE WHEN ICD.period =  5 THEN MFDT.current_forecast_quantity END )  fc_qty_9th     --Ìvæo_X
                 ,SUM( CASE WHEN ICD.period =  5 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_9th     --Ìvæàz_X
                  --PO
                 ,SUM( CASE WHEN ICD.period =  6 THEN MFDT.current_forecast_quantity END )  fc_qty_10th    --Ìvæo_PO
                 ,SUM( CASE WHEN ICD.period =  6 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_10th    --Ìvæàz_PO
                  --PP
                 ,SUM( CASE WHEN ICD.period =  7 THEN MFDT.current_forecast_quantity END )  fc_qty_11th    --Ìvæo_PP
                 ,SUM( CASE WHEN ICD.period =  7 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_11th    --Ìvæàz_PP
                  --PQ
                 ,SUM( CASE WHEN ICD.period =  8 THEN MFDT.current_forecast_quantity END )  fc_qty_12th    --Ìvæo_PQ
                 ,SUM( CASE WHEN ICD.period =  8 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_12th    --Ìvæàz_PQ
                  --P
                 ,SUM( CASE WHEN ICD.period =  9 THEN MFDT.current_forecast_quantity END )  fc_qty_1th     --Ìvæo_P
                 ,SUM( CASE WHEN ICD.period =  9 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_1th     --Ìvæàz_P
                  --Q
                 ,SUM( CASE WHEN ICD.period = 10 THEN MFDT.current_forecast_quantity END )  fc_qty_2th     --Ìvæo_Q
                 ,SUM( CASE WHEN ICD.period = 10 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_2th     --Ìvæàz_Q
                  --R
                 ,SUM( CASE WHEN ICD.period = 11 THEN MFDT.current_forecast_quantity END )  fc_qty_3th     --Ìvæo_R
                 ,SUM( CASE WHEN ICD.period = 11 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_3th     --Ìvæàz_R
                  --S
                 ,SUM( CASE WHEN ICD.period = 12 THEN MFDT.current_forecast_quantity END )  fc_qty_4th     --Ìvæo_S
                 ,SUM( CASE WHEN ICD.period = 12 THEN TO_NUMBER( MFDT.attribute2 )   END )  fc_amt_4th     --Ìvæàz_S
            FROM
                  ic_cldr_dtl                               ICD                 --ÝÉJ_
                 ,mrp_forecast_designators                  MFDN                --tH[LXg¼e[u
                 ,mrp_forecast_dates                        MFDT                --tH[LXgúte[u
           WHERE
             --Ìvæf[^æ¾ð
                  MFDN.attribute1                           = '05'              --05:Ìvæ
             AND (    MFDT.current_forecast_quantity       <> 0
                   OR TO_NUMBER( MFDT.attribute2 )         <> 0
                 )
             AND  MFDN.organization_id                      = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
             AND  MFDN.forecast_designator                  = MFDT.forecast_designator
             AND  MFDN.organization_id                      = MFDT.organization_id
             --ÝÉJ_ÆÌð
             AND  ICD.orgn_code = 'ITOE'
             AND  TO_CHAR( MFDT.forecast_date, 'YYYYMM' )   = TO_CHAR( ICD.period_end_date, 'YYYYMM' )
          GROUP BY
                  ICD.fiscal_year                           --Nx
                 ,MFDN.attribute5                           --¢ã
                 -- 2009/05/12 T.Yoshimoto Mod Start {Ô#1469
                 --,MFDN.attribute3                           --_
                 ,MFDT.attribute5                           --_
                 -- 2009/05/12 T.Yoshimoto Mod End {Ô#1469
                 ,MFDT.inventory_item_id                    --iÚID(INViÚID)
       )                           SMFC                     --ÌvæWv
       ,xxskz_cust_accounts_v      BRCH                     --_¼æ¾piSYSDATEÅLøf[^ðoj
       ,xxskz_item_mst_v           ITEM                     --iÚ¼æ¾piSYSDATEÅLøf[^ðoj
       ,xxskz_prod_class_v         PRODC                    --¤iæªæ¾p
       ,xxskz_item_class_v         ITEMC                    --iÚæªæ¾p
       ,xxskz_crowd_code_v         CROWD                    --QR[hæ¾p
       ,ic_item_mst_b              ITEMB                    --iÚÊè¿æ¾p
 WHERE
   --_¼æ¾iSYSDATEÅLøf[^ðoj
        SMFC.hs_branch             = BRCH.party_number(+)
   --iÚîñæ¾iSYSDATEÅLøf[^ðoj
   AND  SMFC.inv_item_id           = ITEM.inventory_item_id(+)
   --iÚJeSîñæ¾
   AND  ITEM.item_id               = PRODC.item_id(+)       --¤iæª
   AND  ITEM.item_id               = ITEMC.item_id(+)       --iÚæª
   AND  ITEM.item_id               = CROWD.item_id(+)       --QR[h
   --iÚÊè¿æ¾
   AND  ITEM.item_id               = ITEMB.item_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_Ìvænñ_î{_V IS 'XXSKZ_Ìvænñ (î{) VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Nx                    IS 'Nx'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.¢ã                    IS '¢ã'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V._R[h              IS '_R[h'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V._¼                  IS '_¼'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.¤iæª                IS '¤iæª'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.¤iæª¼              IS '¤iæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.iÚæª                IS 'iÚæª'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.iÚæª¼              IS 'iÚæª¼'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.QR[h                IS 'QR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.iÚR[h              IS 'iÚR[h'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.iÚ¼                  IS 'iÚ¼'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.iÚªÌ                IS 'iÚªÌ'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.NÔvP[X        IS 'NÔvP[X'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.NÔvo          IS 'NÔvo'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.NÔvàz            IS 'NÔvàz'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.NÔ|¦                IS 'NÔ|¦'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_T   IS 'ÌvæP[X_T'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_T     IS 'Ìvæo_T'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_T       IS 'Ìvæàz_T'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_T       IS 'Ìvæ|¦_T'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_U   IS 'ÌvæP[X_U'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_U     IS 'Ìvæo_U'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_U       IS 'Ìvæàz_U'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_U       IS 'Ìvæ|¦_U'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_V   IS 'ÌvæP[X_V'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_V     IS 'Ìvæo_V'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_V       IS 'Ìvæàz_V'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_V       IS 'Ìvæ|¦_V'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_W   IS 'ÌvæP[X_W'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_W     IS 'Ìvæo_W'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_W       IS 'Ìvæàz_W'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_W       IS 'Ìvæ|¦_W'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_X   IS 'ÌvæP[X_X'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_X     IS 'Ìvæo_X'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_X       IS 'Ìvæàz_X'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_X       IS 'Ìvæ|¦_X'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_PO IS 'ÌvæP[X_PO'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_PO   IS 'Ìvæo_PO'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_PO     IS 'Ìvæàz_PO'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_PO     IS 'Ìvæ|¦_PO'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_PP IS 'ÌvæP[X_PP'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_PP   IS 'Ìvæo_PP'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_PP     IS 'Ìvæàz_PP'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_PP     IS 'Ìvæ|¦_PP'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_PQ IS 'ÌvæP[X_PQ'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_PQ   IS 'Ìvæo_PQ'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_PQ     IS 'Ìvæàz_PQ'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_PQ     IS 'Ìvæ|¦_PQ'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_P   IS 'ÌvæP[X_P'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_P     IS 'Ìvæo_P'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_P       IS 'Ìvæàz_P'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_P       IS 'Ìvæ|¦_P'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_Q   IS 'ÌvæP[X_Q'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_Q     IS 'Ìvæo_Q'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_Q       IS 'Ìvæàz_Q'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_Q       IS 'Ìvæ|¦_Q'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_R   IS 'ÌvæP[X_R'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_R     IS 'Ìvæo_R'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_R       IS 'Ìvæàz_R'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_R       IS 'Ìvæ|¦_R'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.ÌvæP[X_S   IS 'ÌvæP[X_S'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæo_S     IS 'Ìvæo_S'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæàz_S       IS 'Ìvæàz_S'
/
COMMENT ON COLUMN APPS.XXSKZ_Ìvænñ_î{_V.Ìvæ|¦_S       IS 'Ìvæ|¦_S'
/
