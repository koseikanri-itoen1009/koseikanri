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
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.news_item_header_id     IS '����o�͏��i�w�b�_ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.subject_year            IS '�Ώ۔N�x';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.year_month              IS '�N��';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.indication_order        IS '�\����';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.indication_name         IS '�\������';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.news_division           IS '����敪';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.news_division_code      IS '����敪�R�[�h';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.created_by              IS '�쐬��';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.creation_date           IS '�쐬��';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.last_updated_by         IS '�ŏI�X�V��';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.last_update_date        IS '�ŏI�X�V��';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.last_update_login       IS '�ŏI���O�C��ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.request_id              IS '�v��ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.program_application_id  IS '�v���O�����A�v���P�[�V����ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.program_id              IS '�v���O����ID';
COMMENT ON COLUMN XXCSM_NEWS_ITEM_HEADERS_ALL_V.program_update_date     IS '�v���O�����X�V��';
--
COMMENT ON TABLE  XXCSM_NEWS_ITEM_HEADERS_ALL_V IS '����o�͏��i�w�b�_�r���[';
