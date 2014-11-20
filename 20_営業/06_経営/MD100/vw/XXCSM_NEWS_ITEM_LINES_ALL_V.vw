CREATE OR REPLACE VIEW xxcsm_news_item_lines_all_v
(
    news_item_line_id,
    news_item_header_id,
    item_group_kbn,
    item_group_cd,
    item_group_name,
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
SELECT xnila.news_item_line_id,
       xnila.news_item_header_id,
       xnila.item_group_kbn,
       xnila.item_group_cd,
       xnisv.item_group_name,
       xnila.created_by,
       xnila.creation_date,
       xnila.last_updated_by,
       xnila.last_update_date,
       xnila.last_update_login,
       xnila.request_id,
       xnila.program_application_id,
       xnila.program_id,
       xnila.program_update_date
FROM   xxcsm_news_item_lines_all xnila,
       xxcsm_news_item_select_v  xnisv
WHERE  xnila.item_group_kbn = xnisv.item_group_type
  AND  xnila.item_group_cd  = xnisv.item_group_code
;
--
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.news_item_line_id      IS '速報出力商品明細ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.news_item_header_id    IS '速報出力商品ヘッダID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.item_group_kbn         IS '商品(群)区分';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.item_group_cd          IS '商品(群)コード';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.item_group_name        IS '商品(群)名称';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.created_by             IS '作成者';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.creation_date          IS '作成日';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.last_updated_by        IS '最終更新者';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.last_update_date       IS '最終更新日';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.last_update_login      IS '最終ログインID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.request_id             IS '要求ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.program_application_id IS 'プログラムアプリケーションID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.program_id             IS 'プログラムID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.program_update_date    IS 'プログラム更新日';
--
COMMENT ON TABLE  XXCSM_NEWS_ITEM_LINES_ALL_V IS '速報出力商品明細ビュー';
