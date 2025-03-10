/* 2009/02/26    1.1   SCS H.YOSHITAKE [áQCT_067] ¤iiQjOXgsïÎ */

CREATE OR REPLACE VIEW xxcsm_news_item_select_v
(
    item_group_type
   ,item_group_type_name
   ,item_group_code
   ,item_group_name
)
AS
  SELECT  igv.item_group_type        item_group_type       --¤iæª
         ,flvv.item_group_type_name  item_group_type_name  --¤iæª¼Ì
         ,igv.item_group_code        item_group_code       --¤i(Q)R[h
         ,igv.item_group_name        item_group_name       --¤i(Q)¼Ì
  FROM   (--¤iQ
          SELECT  '1'                item_group_type  --¤iæªi1F¤iQj
                 ,xicv.segment1      item_group_code  --¤iQR[h
                 ,xicv.description   item_group_name  --¼Ì
          FROM   xxcsm_item_category_v xicv
          UNION ALL
          --eíQ
          SELECT  '2'                   item_group_type      --¤iæªi2FeíQj
                 ,flv.lookup_code       item_group_code      --eíQR[h
                 ,flv.meaning           item_group_name      --¼Ì
          FROM    fnd_lookup_values flv           --QÆ^Cv
                 ,xxcsm_process_date_v xpcdv
          WHERE   flv.language = USERENV('LANG')
          AND     flv.lookup_type = 'XXCMM_ITM_YOKIGUN'
          AND     flv.enabled_flag = 'Y'
          AND     NVL(flv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
          AND     NVL(flv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
          UNION ALL
          --iÚ
          SELECT  '3'                    item_group_type     --¤iæªi3F¤ij
                 ,iimb.item_no           item_group_code     --iÚR[h
                 ,iimb.item_desc1        item_group_name     --¼Ì
          FROM   ic_item_mst_b     iimb          --OPMiÚ}X^
                ,xxcmn_item_mst_b  ximb          --OPMiÚAhI
                ,xxcsm_process_date_v xpcdv
          WHERE  iimb.item_id = ximb.item_id
          AND    iimb.inactive_ind <> '1'        --OPMiÚ³øÈO
          AND    ximb.obsolete_class <> '1'      --OPMiÚp~ÈO
--//+ADD START 2009/02/26 CT067 SCS H.YOSHITAKE
          AND     NVL(ximb.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
          AND     NVL(ximb.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
--//+ADD START 2009/02/26 CT067 SCS H.YOSHITAKE
          ) igv
      ,(SELECT flv.lookup_code   item_group_type
              ,flv.meaning       item_group_type_name
        FROM   fnd_lookup_values   flv
              ,xxcsm_process_date_v xpcdv
        WHERE  flv.lookup_type = 'XXCSM1_ITEMGROUP_KBN'
        AND    flv.language = USERENV('LANG')
        AND    flv.enabled_flag = 'Y'
        AND    NVL(flv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
        AND    NVL(flv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
        ) flvv
  WHERE igv.item_group_type = flvv.item_group_type
/
--
COMMENT ON COLUMN xxcsm_news_item_select_v.item_group_type         IS '¤i(Q)æª';
COMMENT ON COLUMN xxcsm_news_item_select_v.item_group_type_name    IS '¤i(Q)æª¼Ì';
COMMENT ON COLUMN xxcsm_news_item_select_v.item_group_code         IS '¤i(Q)R[h';
COMMENT ON COLUMN xxcsm_news_item_select_v.item_group_name         IS '¤i(Q)¼Ì';
--                
COMMENT ON TABLE  xxcsm_news_item_select_v IS '¬ñoÍÎÛ¤iIðr[';
