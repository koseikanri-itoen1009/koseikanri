CREATE OR REPLACE VIEW APPS.XXCFF_LEASE_CONTRACT_DTL_INS_V
(
 CONTRACT_LINE_ID             -- �_�񖾍ד����h�c
,CONTRACT_HEADER_ID           -- �_������h�c
,CONTRACT_LINE_NUM            -- �_��}��
,OBJECT_HEADER_ID             -- ���������h�c
,OBJECT_CODE                  -- �����R�[�h
,DEPARTMENT_NAME              -- �Ǘ����喼
,ASSET_CATEGORY               -- ���Y���
,CATEGORY_NAME                -- ���Y��ޖ�
,FIRST_INSTALLATION_PLACE     -- ����ݒu��
,FIRST_INSTALLATION_ADDRESS   -- ����ݒu�ꏊ
,CONTRACT_STATUS              -- �_��X�e�[�^�X
,CONTRACT_STATUS_NAME         -- �_��X�e�[�^�X��
,FIRST_CHARGE                 -- ���񌎊z���[�X���E���[�X��
,FIRST_TAX_CHARGE             -- ���񌎊z����ŁE���[�X��
,FIRST_TOTAL_CHARGE           -- ����v�E���[�X��
,SECOND_CHARGE                -- 2��ڈȍ~���z���[�X���E���[�X��
,SECOND_TAX_CHARGE            -- 2��ڈȍ~���z����ŁE���[�X��
,SECOND_TOTAL_CHARGE          -- 2��ڈȍ~�v�E���[�X��
,FIRST_DEDUCTION              -- ���񌎊z���[�X�E�T���z
,FIRST_TAX_DEDUCTION          -- ���񌎊z����ŁE�T���z
,FIRST_TOTAL_DEDUCTION        -- ����v�E�T���z
,SECOND_DEDUCTION             -- 2��ڈȍ~���z���[�X���E�T���z
,SECOND_TAX_DEDUCTION         -- 2��ڈȍ~���z����ŁE�T���z
,SECOND_TOTAL_DEDUCTION       -- 2��ڈȍ~�v�E�T���z
,FIRST_AFTER_DEDUCTION        -- ���񌎊z���[�X�E�T����
,FIRST_TAX_AFTER_DEDUCTION    -- ���񌎊z����ŁE�T����
,FIRST_TOTAL_AFTER_DEDUCTION  -- ����v�E�T����
,SECOND_AFTER_DEDUCTION       -- 2��ڈȍ~���z���[�X���E�T����
,SECOND_TAX_AFTER_DEDUCTION   -- 2��ڈȍ~���z����ŁE�T����
,SECOND_TOTAL_AFTER_DEDUCTION -- 2��ڈȍ~�v�E�T����
,GROSS_CHARGE                 -- ���z���[�X���E���[�X��
,GROSS_TAX_CHARGE             -- ���z����ŁE���[�X��
,GROSS_TOTAL_CHARGE           -- ���z�v�E���[�X��
,GROSS_DEDUCTION              -- ���z���[�X���E�T���z
,GROSS_TAX_DEDUCTION          -- ���z����ŁE�T���z
,GROSS_TOTAL_DEDUCTION        -- ���z�v�E�T���z
,GROSS_AFTER_DEDUCTION        -- ���z���[�X���E�T����
,GROSS_TAX_AFTER_DEDUCTION    -- ���z����ŁE�T����
,GROSS_TOTAL_AFTER_DEDUCTION  -- ���z�v�E�T����
,ESTIMATED_CASH_PRICE         -- ���ό����w�����z
,PRESENT_VALUE_DISCOUNT_RATE  -- ���݉��l������
,PRESENT_VALUE                -- ���݉��l
,PRESENT_VALUE_STANDARD       -- �A�^�@
,LIFE_IN_MONTHS               -- �@��ϗp�N��
,LIFE_IN_MONTHS_STANDARD      -- �C�^�B
,LEASE_KIND                   -- ���[�X���
,LEASE_KIND_NAME              -- ���[�X��ޖ�
,ORIGINAL_COST                -- �擾���z
,CALC_INTERESTED_RATE         -- �v�Z���q��
,PAYMENT_YEARS                -- �N��
,CREATED_BY                   -- �쐬��
,CREATION_DATE                -- �쐬��
,LAST_UPDATED_BY              -- �ŏI�X�V��
,LAST_UPDATE_DATE             -- �ŏI�X�V��
,LAST_UPDATE_LOGIN            -- �ŏI�X�V���O�C��
,REQUEST_ID                   -- �v��ID
,PROGRAM_APPLICATION_ID       -- �ݶ��ĥ��۸��ѥ���ع����ID
,PROGRAM_ID                   -- �ݶ��ĥ��۸���ID
,PROGRAM_UPDATE_DATE          -- ��۸��эX�V��
,ROW_ID                       -- ROWID
,OBJECT_UPDATE_DATE           -- �����w�b�_�ŏI�X�V��
,PLAN_UPDATE_DATE             -- �x���v��ŏI�X�V��
)
AS
SELECT XCL.CONTRACT_LINE_ID                                        AS CONTRACT_LINE_ID
      ,XCL.CONTRACT_HEADER_ID                                      AS CONTRACT_HEADER_ID
      ,XCL.CONTRACT_LINE_NUM                                       AS CONTRACT_LINE_NUM
      ,XCL.OBJECT_HEADER_ID                                        AS OBJECT_HEADER_ID
      ,XOH.OBJECT_CODE                                             AS OBJECT_CODE
      ,XDV.DEPARTMENT_NAME                                         AS DEPARTMENT_NAME
      ,XCL.ASSET_CATEGORY                                          AS ASSET_CATEGORY
      ,XCV.CATEGORY_NAME                                           AS CATEGORY_NAME
      ,XCL.FIRST_INSTALLATION_PLACE                                AS FIRST_INSTALLATION_PLACE
      ,XCL.FIRST_INSTALLATION_ADDRESS                              AS FIRST_INSTALLATION_ADDRESS
      ,XCL.CONTRACT_STATUS                                         AS CONTRACT_STATUS
      ,XCS.CONTRACT_STATUS_NAME                                    AS CONTRACT_STATUS_NAME
      ,XCL.FIRST_CHARGE                                            AS FIRST_CHARGE
      ,XCL.FIRST_TAX_CHARGE                                        AS FIRST_TAX_CHARGE
      ,XCL.FIRST_TOTAL_CHARGE                                      AS FIRST_TOTAL_CHARGE
      ,XCL.SECOND_CHARGE                                           AS SECOND_CHARGE
      ,XCL.SECOND_TAX_CHARGE                                       AS SECOND_TAX_CHARGE
      ,XCL.SECOND_TOTAL_CHARGE                                     AS SECOND_TOTAL_CHARGE
      ,XCL.FIRST_DEDUCTION                                         AS FIRST_DEDUCTION
      ,XCL.FIRST_TAX_DEDUCTION                                     AS FIRST_TAX_DEDUCTION
      ,XCL.FIRST_TOTAL_DEDUCTION                                   AS FIRST_TOTAL_DEDUCTION
      ,XCL.SECOND_DEDUCTION                                        AS SECOND_DEDUCTION
      ,XCL.SECOND_TAX_DEDUCTION                                    AS SECOND_TAX_DEDUCTION
      ,XCL.SECOND_TOTAL_DEDUCTION                                  AS SECOND_TOTAL_DEDUCTION
      ,XCL.FIRST_CHARGE        - XCL.FIRST_DEDUCTION               AS FIRST_AFTER_DEDUCTION
      ,XCL.FIRST_TAX_CHARGE    - XCL.FIRST_TAX_DEDUCTION           AS FIRST_TAX_AFTER_DEDUCTION
      ,XCL.FIRST_TOTAL_CHARGE  - XCL.FIRST_TOTAL_DEDUCTION         AS FIRST_TOTAL_AFTER_DEDUCTION
      ,XCL.SECOND_CHARGE       - XCL.SECOND_DEDUCTION              AS SECOND_AFTER_DEDUCTION
      ,XCL.SECOND_TAX_CHARGE   - XCL.SECOND_TAX_DEDUCTION          AS SECOND_TAX_AFTER_DEDUCTION
      ,XCL.SECOND_TOTAL_CHARGE - XCL.SECOND_TOTAL_DEDUCTION        AS SECOND_TOTAL_AFTER_DEDUCTION
      ,XCL.GROSS_CHARGE                                            AS GROSS_CHARGE
      ,XCL.GROSS_TAX_CHARGE                                        AS GROSS_TAX_CHARGE
      ,XCL.GROSS_TOTAL_CHARGE                                      AS GROSS_TOTAL_CHARGE
      ,XCL.GROSS_DEDUCTION                                         AS GROSS_DEDUCTION
      ,XCL.GROSS_TAX_DEDUCTION                                     AS GROSS_TAX_DEDUCTION
      ,XCL.GROSS_TOTAL_DEDUCTION                                   AS GROSS_TOTAL_DEDUCTION
      ,XCL.GROSS_CHARGE       - XCL.GROSS_DEDUCTION                AS GROSS_AFTER_DEDUCTION
      ,XCL.GROSS_TAX_CHARGE   - XCL.GROSS_TAX_DEDUCTION            AS GROSS_TAX_AFTER_DEDUCTION
      ,XCL.GROSS_TOTAL_CHARGE - XCL.GROSS_TOTAL_DEDUCTION          AS GROSS_TOTAL_AFTER_DEDUCTION
      ,XCL.ESTIMATED_CASH_PRICE                                    AS ESTIMATED_CASH_PRICE
      ,XCL.PRESENT_VALUE_DISCOUNT_RATE * 100                       AS PRESENT_VALUE_DISCOUNT_RATE
      ,XCL.PRESENT_VALUE                                           AS PRESENT_VALUE
      ,ROUND(XCL.PRESENT_VALUE / XCL.ESTIMATED_CASH_PRICE * 100)   AS PRESENT_VALUE_STANDARD
      ,XCL.LIFE_IN_MONTHS                                          AS LIFE_IN_MONTHS
      ,ROUND(XCH.PAYMENT_YEARS / XCL.LIFE_IN_MONTHS * 100)         AS LIFE_IN_MONTHS_STANDARD
      ,XCL.LEASE_KIND                                              AS LEASE_KIND
      ,XLK.LEASE_KIND_NAME                                         AS LEASE_KIND_NAME
      ,XCL.ORIGINAL_COST                                           AS ORIGINAL_COST
      ,XCL.CALC_INTERESTED_RATE * 100                              AS CALC_INTERESTED_RATE
      ,XCH.PAYMENT_YEARS                                           AS PAYMENT_YEARS
      ,XCL.CREATED_BY                                              AS CREATED_BY
      ,XCL.CREATION_DATE                                           AS CREATION_DATE
      ,XCL.LAST_UPDATED_BY                                         AS LAST_UPDATED_BY
      ,XCL.LAST_UPDATE_DATE                                        AS LAST_UPDATE_DATE
      ,XCL.LAST_UPDATE_LOGIN                                       AS LAST_UPDATE_LOGIN
      ,XCL.REQUEST_ID                                              AS REQUEST_ID
      ,XCL.PROGRAM_APPLICATION_ID                                  AS PROGRAM_APPLICATION_ID
      ,XCL.PROGRAM_ID                                              AS PROGRAM_ID
      ,XCL.PROGRAM_UPDATE_DATE                                     AS PROGRAM_UPDATE_DATE
      ,XCL.ROWID                                                   AS ROW_ID
      ,XOH.LAST_UPDATE_DATE                                        AS OBJECT_UPDATE_DATE
      ,XPP.PLAN_UPDATE_DATE                                        AS PLAN_UPDATE_DATE
FROM   XXCFF_CONTRACT_HEADERS  XCH
      ,XXCFF_CONTRACT_LINES    XCL
      ,XXCFF_OBJECT_HEADERS    XOH
      ,XXCFF_DEPARTMENT_V      XDV
      ,XXCFF_CATEGORY_V        XCV
      ,XXCFF_CONTRACT_STATUS_V XCS
      ,XXCFF_LEASE_KIND_V      XLK
      ,(SELECT MAX(LAST_UPDATE_DATE) AS PLAN_UPDATE_DATE
              ,CONTRACT_LINE_ID
        FROM  XXCFF_PAY_PLANNING
        GROUP BY CONTRACT_LINE_ID) XPP
 WHERE XCH.CONTRACT_HEADER_ID = XCL.CONTRACT_HEADER_ID
 AND   XCL.OBJECT_HEADER_ID   = XOH.OBJECT_HEADER_ID
 AND   XCL.CONTRACT_LINE_ID   = XPP.CONTRACT_LINE_ID
 AND   XOH.DEPARTMENT_CODE    = XDV.DEPARTMENT_CODE
 AND   XCL.ASSET_CATEGORY     = XCV.CATEGORY_CODE
 AND   XCL.CONTRACT_STATUS    = XCS.CONTRACT_STATUS_CODE
 AND   XCL.LEASE_KIND         = XLK.LEASE_KIND_CODE
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CONTRACT_LINE_ID             IS '�_�񖾍ד����h�c'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CONTRACT_HEADER_ID           IS '�_������h�c'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CONTRACT_LINE_NUM            IS '�_��}��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.OBJECT_HEADER_ID             IS '���������h�c'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.OBJECT_CODE                  IS '�����R�[�h'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.DEPARTMENT_NAME              IS '�Ǘ����喼'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.ASSET_CATEGORY               IS '���Y���'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CATEGORY_NAME                IS '���Y��ޖ�'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_INSTALLATION_PLACE     IS '����ݒu��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_INSTALLATION_ADDRESS   IS '����ݒu�ꏊ'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CONTRACT_STATUS              IS '�_��X�e�[�^�X'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CONTRACT_STATUS_NAME         IS '�_��X�e�[�^�X��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_CHARGE                 IS '���񌎊z���[�X���E���[�X��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TAX_CHARGE             IS '���񌎊z����ŁE���[�X��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TOTAL_CHARGE           IS '����v�E���[�X��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_CHARGE                IS '2��ڈȍ~���z���[�X���E���[�X��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TAX_CHARGE            IS '2��ڈȍ~���z����ŁE���[�X��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TOTAL_CHARGE          IS '2��ڈȍ~�v�E���[�X��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_DEDUCTION              IS '���񌎊z���[�X�E�T���z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TAX_DEDUCTION          IS '���񌎊z����ŁE�T���z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TOTAL_DEDUCTION        IS '����v�E�T���z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_DEDUCTION             IS '2��ڈȍ~���z���[�X���E�T���z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TAX_DEDUCTION         IS '2��ڈȍ~���z����ŁE�T���z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TOTAL_DEDUCTION       IS '2��ڈȍ~�v�E�T���z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_AFTER_DEDUCTION        IS '���񌎊z���[�X�E�T����'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TAX_AFTER_DEDUCTION    IS '���񌎊z����ŁE�T����'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.FIRST_TOTAL_AFTER_DEDUCTION  IS '����v�E�T����'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_AFTER_DEDUCTION       IS '2��ڈȍ~���z���[�X���E�T����'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TAX_AFTER_DEDUCTION   IS '2��ڈȍ~���z����ŁE�T����'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.SECOND_TOTAL_AFTER_DEDUCTION IS '2��ڈȍ~�v�E�T����'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_CHARGE                 IS '���z���[�X���E���[�X��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TAX_CHARGE             IS '���z����ŁE���[�X��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TOTAL_CHARGE           IS '���z�v�E���[�X��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_DEDUCTION              IS '���z���[�X���E�T���z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TAX_DEDUCTION          IS '���z����ŁE�T���z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TOTAL_DEDUCTION        IS '���z�v�E�T���z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_AFTER_DEDUCTION        IS '���z���[�X���E�T����'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TAX_AFTER_DEDUCTION    IS '���z����ŁE�T����'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.GROSS_TOTAL_AFTER_DEDUCTION  IS '���z�v�E�T����'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.ESTIMATED_CASH_PRICE         IS '���ό����w�����z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PRESENT_VALUE_DISCOUNT_RATE  IS '���݉��l������'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PRESENT_VALUE                IS '���݉��l'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PRESENT_VALUE_STANDARD       IS '�A�^�@'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LIFE_IN_MONTHS               IS '�@��ϗp�N��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LIFE_IN_MONTHS_STANDARD      IS '�C�^�B'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LEASE_KIND                   IS '���[�X���'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LEASE_KIND_NAME              IS '���[�X��ޖ�'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.ORIGINAL_COST                IS '�擾���z'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CALC_INTERESTED_RATE         IS '�v�Z���q��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PAYMENT_YEARS                IS '�N��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CREATED_BY                   IS '�쐬��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.CREATION_DATE                IS '�쐬��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LAST_UPDATED_BY              IS '�ŏI�X�V��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LAST_UPDATE_DATE             IS '�ŏI�X�V��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.LAST_UPDATE_LOGIN            IS '�ŏI�X�V���O�C��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.REQUEST_ID                   IS '�v��ID'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PROGRAM_APPLICATION_ID       IS '�ݶ��ĥ��۸��ѥ���ع����ID'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PROGRAM_ID                   IS '�ݶ��ĥ��۸���ID'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PROGRAM_UPDATE_DATE          IS '��۸��эX�V��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.ROW_ID                       IS 'ROW_ID'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.OBJECT_UPDATE_DATE           IS '�����w�b�_�ŏI�X�V��'
/
COMMENT ON COLUMN XXCFF_LEASE_CONTRACT_DTL_INS_V.PLAN_UPDATE_DATE             IS '�x���v��ŏI�X�V��'
/
COMMENT ON TABLE XXCFF_LEASE_CONTRACT_DTL_INS_V IS '���[�X�_��o�^��ʖ��׃r���['
/
