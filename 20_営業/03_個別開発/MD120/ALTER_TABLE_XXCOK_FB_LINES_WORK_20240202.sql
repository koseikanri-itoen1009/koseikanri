ALTER TABLE XXCOK.XXCOK_FB_LINES_WORK
ADD(
     company_code                   VARCHAR2(30)
    ,settlement_priority            VARCHAR2(1)
)
/
COMMENT ON COLUMN xxcok.xxcok_fb_lines_work.company_code                               IS '��ЃR�[�h'
/
COMMENT ON COLUMN xxcok.xxcok_fb_lines_work.settlement_priority                        IS '�U���w��敪�i���ϗD��x�j'
/
