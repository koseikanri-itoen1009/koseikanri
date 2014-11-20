/* 2009/02/26    1.1   SCS H.YOSHITAKE [障害CT_067] 商品（群）ロングリスト不具合対応 */

CREATE OR REPLACE VIEW xxcsm_news_item_select_v
(
    item_group_type
   ,item_group_type_name
   ,item_group_code
   ,item_group_name
)
AS
  SELECT  igv.item_group_type        item_group_type       --商品区分
         ,flvv.item_group_type_name  item_group_type_name  --商品区分名称
         ,igv.item_group_code        item_group_code       --商品(群)コード
         ,igv.item_group_name        item_group_name       --商品(群)名称
  FROM   (--商品群
          SELECT  '1'                item_group_type  --商品区分（1：商品群）
                 ,xicv.segment1      item_group_code  --商品群コード
                 ,xicv.description   item_group_name  --名称
          FROM   xxcsm_item_category_v xicv
          UNION ALL
          --容器群
          SELECT  '2'                   item_group_type      --商品区分（2：容器群）
                 ,flv.lookup_code       item_group_code      --容器群コード
                 ,flv.meaning           item_group_name      --名称
          FROM    fnd_lookup_values flv           --参照タイプ
                 ,xxcsm_process_date_v xpcdv
          WHERE   flv.language = USERENV('LANG')
          AND     flv.lookup_type = 'XXCMM_ITM_YOKIGUN'
          AND     flv.enabled_flag = 'Y'
          AND     NVL(flv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
          AND     NVL(flv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
          UNION ALL
          --品目
          SELECT  '3'                    item_group_type     --商品区分（3：商品）
                 ,iimb.item_no           item_group_code     --品目コード
                 ,iimb.item_desc1        item_group_name     --名称
          FROM   ic_item_mst_b     iimb          --OPM品目マスタ
                ,xxcmn_item_mst_b  ximb          --OPM品目アドオン
                ,xxcsm_process_date_v xpcdv
          WHERE  iimb.item_id = ximb.item_id
          AND    iimb.inactive_ind <> '1'        --OPM品目無効以外
          AND    ximb.obsolete_class <> '1'      --OPM品目廃止以外
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
COMMENT ON COLUMN xxcsm_news_item_select_v.item_group_type         IS '商品(群)区分';
COMMENT ON COLUMN xxcsm_news_item_select_v.item_group_type_name    IS '商品(群)区分名称';
COMMENT ON COLUMN xxcsm_news_item_select_v.item_group_code         IS '商品(群)コード';
COMMENT ON COLUMN xxcsm_news_item_select_v.item_group_name         IS '商品(群)名称';
--                
COMMENT ON TABLE  xxcsm_news_item_select_v IS '速報出力対象商品選択ビュー';
