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
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.news_item_line_id      IS '����o�͏��i����ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.news_item_header_id    IS '����o�͏��i�w�b�_ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.item_group_kbn         IS '���i(�Q)�敪';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.item_group_cd          IS '���i(�Q)�R�[�h';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.item_group_name        IS '���i(�Q)����';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.created_by             IS '�쐬��';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.creation_date          IS '�쐬��';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.last_updated_by        IS '�ŏI�X�V��';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.last_update_date       IS '�ŏI�X�V��';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.last_update_login      IS '�ŏI���O�C��ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.request_id             IS '�v��ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.program_application_id IS '�v���O�����A�v���P�[�V����ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.program_id             IS '�v���O����ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_LINES_ALL_V.program_update_date    IS '�v���O�����X�V��';
--
COMMENT ON TABLE  XXCSM_NEWS_ITEM_LINES_ALL_V IS '����o�͏��i���׃r���[';
