ALTER TABLE XXCOK.XXCOK_FB_LINES_WORK
ADD(
     company_code                   VARCHAR2(30)
    ,settlement_priority            VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcok.xxcok_fb_lines_work.company_code                               IS '会社コード'
/
COMMENT ON COLUMN xxcok.xxcok_fb_lines_work.settlement_priority                        IS '振込指定区分（決済優先度）'
/
