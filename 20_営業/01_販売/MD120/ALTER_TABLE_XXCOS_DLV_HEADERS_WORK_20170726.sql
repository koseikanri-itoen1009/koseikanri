ALTER TABLE xxcos.xxcos_dlv_headers_work ADD (
   visit_class1  VARCHAR2(2)
  ,visit_class2  VARCHAR2(2)
  ,visit_class3  VARCHAR2(2)
  ,visit_class4  VARCHAR2(2)
  ,visit_class5  VARCHAR2(2)
);
COMMENT ON COLUMN xxcos.xxcos_dlv_headers_work.visit_class1 IS '�K��敪1';
COMMENT ON COLUMN xxcos.xxcos_dlv_headers_work.visit_class2 IS '�K��敪2';
COMMENT ON COLUMN xxcos.xxcos_dlv_headers_work.visit_class3 IS '�K��敪3';
COMMENT ON COLUMN xxcos.xxcos_dlv_headers_work.visit_class4 IS '�K��敪4';
COMMENT ON COLUMN xxcos.xxcos_dlv_headers_work.visit_class5 IS '�K��敪5';
