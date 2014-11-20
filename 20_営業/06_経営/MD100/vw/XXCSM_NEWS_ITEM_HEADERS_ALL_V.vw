CREATE OR REPLACE VIEW xxcsm_news_item_headers_all_v
(
  news_item_header_id,
  subject_year,
  year_month,
  indication_order,
  indication_name,
  news_division,
  news_division_code,
  created_by,
  creation_date,
  last_updated_by,
  last_update_date,
  last_update_login,
  request_id,
  program_application_id,
  program_id,
  program_update_date
)
AS
SELECT xniha.news_item_header_id,
       xniha.subject_year,
       xniha.year_month,
       xniha.indication_order,
       xniha.indication_name,
       flv.meaning,
       xniha.news_division_code,
       xniha.created_by,
       xniha.creation_date,
       xniha.last_updated_by,
       xniha.last_update_date,
       xniha.last_update_login,
       xniha.request_id,
       xniha.program_application_id,
       xniha.program_id,
       xniha.program_update_date
FROM   xxcsm_news_item_headers_all xniha,
       fnd_lookup_values flv
      ,xxcsm_process_date_v xpcdv
WHERE  xniha.news_division_code = flv.lookup_code
AND    flv.language = USERENV('LANG')
AND    flv.lookup_type = 'XXCSM1_NEWS_ITEM_KBN'
AND    flv.enabled_flag = 'Y'
AND    NVL(flv.start_date_active,xpcdv.process_date)  <= xpcdv.process_date
AND    NVL(flv.end_date_active,xpcdv.process_date)    >= xpcdv.process_date
;
--
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.news_item_header_id     IS '速報出力商品ヘッダID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.subject_year            IS '対象年度';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.year_month              IS '年月';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.indication_order        IS '表示順';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.indication_name         IS '表示名称';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.news_division           IS '速報区分';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.news_division_code      IS '速報区分コード';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.created_by              IS '作成者';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.creation_date           IS '作成日';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.last_updated_by         IS '最終更新者';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.last_update_date        IS '最終更新日';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.last_update_login       IS '最終ログインID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.request_id              IS '要求ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.program_application_id  IS 'プログラムアプリケーションID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.program_id              IS 'プログラムID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.program_update_date     IS 'プログラム更新日';
--
COMMENT ON TABLE  XXCSM_NEWS_ITEM_HEADERS_ALL_V IS '速報出力商品ヘッダビュー';
