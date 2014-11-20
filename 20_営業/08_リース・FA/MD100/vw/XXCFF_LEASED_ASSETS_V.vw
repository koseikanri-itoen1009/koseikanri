CREATE OR REPLACE FORCE VIEW XXCFF_LEASED_ASSETS_V
(
LEASE_CLASS                  --���[�X��ʃR�[�h
,LEASE_CLASS_NAME            --���[�X���
,CONTRACT_NUMBER             --�_��ԍ�
,LEASE_TYPE                  --���[�X�敪
,LEASE_TYPE_NAME
,LEASE_COMPANY               --���[�X��ЃR�[�h
,PAYMENT_FREQUENCY           --�x����
,PAYMENT_TYPE                --�p�x
,CONTRACT_DATE               --�_���
,LEASE_START_DATE            --���[�X�J�n��
,LEASE_END_DATE              --���[�X�I����
,LEASE_KIND                  --���[�X���
,CONTRACT_LINE_NUM           --�_��}��
,FIRST_INSTALLATION_ADDRESS  --����ݒu�ꏊ
,FIRST_INSTALLATION_PLACE    --����ݒu��
,EXPIRATION_DATE             --������
,CANCELLATION_DATE           --���r����
,ORIGINAL_COST               --�擾���z
,FIRST_CHARGE                --���񌎊z���[�X�i�Ŕ��j
,FIRST_TAX_CHARGE            --���񌎊z����Ŋz
,FIRST_TOTAL_CHARGE          --���񌎊z���[�X�i�ō��j
,SECOND_CHARGE               --�Q��ڈȍ~���z���[�X���i�Ŕ��j
,SECOND_TAX_CHARGE           --�Q��ڈȍ~���z����Ŋz
,SECOND_TOTAL_CHARGE         --�Q��ڈȍ~���z���[�X�i�ō��j
,FIRST_DEDUCTION             --���z���[�X�T���z�i�Ŕ��j
,FIRST_TAX_DEDUCTION         --���z���[�X�T������Ŋz
,FIRST_TOTAL_DEDUCTION       --���z���[�X�T���z�i�ō��j
,GROSS_CHARGE                --���[�X�����z�i�Ŕ��j
,GROSS_TAX_CHARGE            --���[�X����ő��z
,GROSS_TOTAL_CHARGE          --���[�X�����z�i�ō��j
,GROSS_DEDUCTION             --�T���z���z�i�Ŕ��j
,GROSS_TAX_DEDUCTION         --�T���z����ő��z
,GROSS_TOTAL_DEDUCTION       --�T���z���z�i�ō��j
,DEPARTMENT_CODE             --�Ǘ�����R�[�h
,OWNER_COMPANY               --�{��/�H��敪
,OBJECT_CODE                 --�����R�[�h
,CHASSIS_NUMBER              --�ԑ�ԍ�
,RE_LEASE_TIMES              --�ă��[�X��
,AGE_TYPE                    --�N��
,MODEL                       --�@��
,SERIAL_NUMBER               --�@��
,MANUFACTURER_NAME           --���[�J�[���i�����Җ��j
,INSTALLATION_ADDRESS        --���ݒu�ꏊ
,INSTALLATION_PLACE          --���ݒu��
,CANCELLATION_TYPE           --���r���敪
,CANCELLATION_TYPE_NAME      --���r���敪����
,BOND_ACCEPTANCE_DATE        --�؏���̓�
,OBJECT_STATUS               --�����X�e�[�^�X
,SEGMENT2_DESC               --�Ǘ�����
,LEASE_CLASS_CODE            --���[�X���
,LEASE_COMPANY_CODE          --���[�X��ЃR�[�h
,LEASE_COMPANY_NAME          --���[�X���
,LAST_UPDATE_DATE            --�ŏI�X�V��
,LAST_UPDATED_BY             --�ŏI�X�V��
,CREATED_BY                  --�쐬��
,CREATION_DATE               --�쐬��
,LAST_UPDATE_LOGIN           --�ŏI�X�V���O�C��
)
AS 
SELECT  XOH.LEASE_CLASS                 --���[�X��ʃR�[�h
       ,XLCV.LEASE_CLASS_NAME           --���[�X���
       ,CON.CONTRACT_NUMBER             --�_��ԍ�
       ,XOH.LEASE_TYPE                  --���[�X�敪
       ,XLTV.LEASE_TYPE_NAME            --���[�X�敪����
       ,CON.LEASE_COMPANY               --���[�X��ЃR�[�h
       ,CON.PAYMENT_FREQUENCY           --�x����
       ,CON.PAYMENT_TYPE                --�p�x
       ,CON.CONTRACT_DATE               --�_���
       ,CON.LEASE_START_DATE            --���[�X�J�n��
       ,CON.LEASE_END_DATE              --���[�X�I����
       ,CON.LEASE_KIND                  --���[�X���
       ,CON.CONTRACT_LINE_NUM           --�_��}��
       ,CON.FIRST_INSTALLATION_ADDRESS  --����ݒu�ꏊ
       ,CON.FIRST_INSTALLATION_PLACE    --����ݒu��
       ,CON.EXPIRATION_DATE             --������
       ,CON.CANCELLATION_DATE           --���r����
       ,CON.ORIGINAL_COST               --�擾���z
       ,CON.FIRST_CHARGE                --���񌎊z���[�X�i�Ŕ��j
       ,CON.FIRST_TAX_CHARGE            --���񌎊z����Ŋz
       ,CON.FIRST_TOTAL_CHARGE          --���񌎊z���[�X�i�ō��j
       ,CON.SECOND_CHARGE               --�Q��ڈȍ~���z���[�X���i�Ŕ��j
       ,CON.SECOND_TAX_CHARGE           --�Q��ڈȍ~���z����Ŋz
       ,CON.SECOND_TOTAL_CHARGE         --�Q��ڈȍ~���z���[�X�i�ō��j
       ,CON.FIRST_DEDUCTION             --���z���[�X�T���z�i�Ŕ��j
       ,CON.FIRST_TAX_DEDUCTION         --���z���[�X�T������Ŋz
       ,CON.FIRST_TOTAL_DEDUCTION       --���z���[�X�T���z�i�ō��j
       ,CON.GROSS_CHARGE                --���[�X�����z�i�Ŕ��j
       ,CON.GROSS_TAX_CHARGE            --���[�X����ő��z
       ,CON.GROSS_TOTAL_CHARGE          --���[�X�����z�i�ō��j
       ,CON.GROSS_DEDUCTION             --�T���z���z�i�Ŕ��j
       ,CON.GROSS_TAX_DEDUCTION         --�T���z����ő��z
       ,CON.GROSS_TOTAL_DEDUCTION       --�T���z���z�i�ō��j
       ,XOH.DEPARTMENT_CODE             --�Ǘ�����R�[�h
       ,XOH.OWNER_COMPANY               --�{��/�H��敪
       ,XOH.OBJECT_CODE                 --�����R�[�h
       ,XOH.CHASSIS_NUMBER              --�ԑ�ԍ�
       ,XOH.RE_LEASE_TIMES              --�ă��[�X��
       ,XOH.AGE_TYPE                    --�N��
       ,XOH.MODEL                       --�@��
       ,XOH.SERIAL_NUMBER               --�@��
       ,XOH.MANUFACTURER_NAME           --���[�J�[���i�����Җ��j
       ,XOH.INSTALLATION_ADDRESS        --���ݒu�ꏊ
       ,XOH.INSTALLATION_PLACE          --���ݒu��
       ,XOH.CANCELLATION_TYPE           --���r���敪
       ,XCTV.CANCELLATION_TYPE_NAME     --���r���敪����
       ,XOH.BOND_ACCEPTANCE_DATE        --�؏���̓�
       ,XOH.OBJECT_STATUS AS  SEGMENT2_DESC--�����X�e�[�^�X
       ,XDV.DEPARTMENT_NAME              --�Ǘ�����
       ,XLCV.LEASE_CLASS_CODE           --���[�X���
       ,CON.LEASE_COMPANY_CODE        --���[�X���
       ,CON.LEASE_COMPANY_NAME        --���[�X��Ж�
       ,XOH.LAST_UPDATE_DATE          --�ŏI�X�V��
       ,XOH.LAST_UPDATED_BY           --�ŏI�X�V��
       ,XOH.CREATED_BY                --�쐬��
       ,XOH.CREATION_DATE             --�쐬��
       ,XOH.LAST_UPDATE_LOGIN         --�ŏI�X�V���O�C��
FROM    XXCFF_OBJECT_HEADERS      XOH    --���[�X����
       ,XXCFF_DEPARTMENT_V        XDV   --���Ə��}�X�^VIEW
       ,XXCFF_LEASE_CLASS_V       XLCV   --���[�X��ʃr���[
       ,XXCFF_LEASE_TYPE_V        XLTV   --���[�X�敪�r���[
       ,XXCFF_CANCELLATION_TYPE_V XCTV   --���[�X���敪�r���[
       ,(SELECT  XCH.LEASE_CLASS                 --���[�X��ʃR�[�h
                ,XCH.RE_LEASE_TIMES
                ,XCH.CONTRACT_NUMBER             --�_��ԍ�
--                ,XCH.LEASE_TYPE                  --���[�X�敪
                ,XCH.LEASE_COMPANY               --���[�X��ЃR�[�h
                ,XCH.PAYMENT_FREQUENCY           --�x����
                ,XCH.PAYMENT_TYPE                --�p�x
                ,XCH.CONTRACT_DATE               --�_���
                ,XCH.LEASE_START_DATE            --���[�X�J�n��
                ,XCH.LEASE_END_DATE              --���[�X�I����
                ,XCL.OBJECT_HEADER_ID
                ,XCL.LEASE_KIND                  --���[�X���
                ,XCL.CONTRACT_LINE_NUM           --�_��}��
                ,XCL.FIRST_INSTALLATION_ADDRESS  --����ݒu�ꏊ
                ,XCL.FIRST_INSTALLATION_PLACE    --����ݒu��
                ,XCL.EXPIRATION_DATE             --������
                ,XCL.CANCELLATION_DATE           --���r����
                ,XCL.ORIGINAL_COST               --�擾���z
                ,XCL.FIRST_CHARGE                --���񌎊z���[�X�i�Ŕ��j
                ,XCL.FIRST_TAX_CHARGE            --���񌎊z����Ŋz
                ,XCL.FIRST_TOTAL_CHARGE          --���񌎊z���[�X�i�ō��j
                ,XCL.SECOND_CHARGE               --�Q��ڈȍ~���z���[�X���i�Ŕ��j
                ,XCL.SECOND_TAX_CHARGE           --�Q��ڈȍ~���z����Ŋz
                ,XCL.SECOND_TOTAL_CHARGE         --�Q��ڈȍ~���z���[�X�i�ō��j
                ,XCL.FIRST_DEDUCTION             --���z���[�X�T���z�i�Ŕ��j
                ,XCL.FIRST_TAX_DEDUCTION         --���z���[�X�T������Ŋz
                ,XCL.FIRST_TOTAL_DEDUCTION       --���z���[�X�T���z�i�ō��j
                ,XCL.GROSS_CHARGE                --���[�X�����z�i�Ŕ��j
                ,XCL.GROSS_TAX_CHARGE            --���[�X����ő��z
                ,XCL.GROSS_TOTAL_CHARGE          --���[�X�����z�i�ō��j
                ,XCL.GROSS_DEDUCTION             --�T���z���z�i�Ŕ��j
                ,XCL.GROSS_TAX_DEDUCTION         --�T���z����ő��z
                ,XCL.GROSS_TOTAL_DEDUCTION       --�T���z���z�i�ō��j
                ,XLCOV.LEASE_COMPANY_CODE        --���[�X���
                ,XLCOV.LEASE_COMPANY_NAME        --���[�X��Ж�
         FROM    XXCFF_CONTRACT_HEADERS XCH      --���[�X�_��
                ,XXCFF_CONTRACT_LINES   XCL      --���[�X�_�񖾍�
                ,XXCFF_LEASE_COMPANY_V  XLCOV    --���[�X��Ѓr���[
         WHERE   XCH.CONTRACT_HEADER_ID   = XCL.CONTRACT_HEADER_ID
         AND     XCH.LEASE_COMPANY        = XLCOV.LEASE_COMPANY_CODE) CON
WHERE XOH.OBJECT_HEADER_ID     = CON.OBJECT_HEADER_ID(+)
AND   XOH.RE_LEASE_TIMES       = CON.RE_LEASE_TIMES(+)
AND   XOH.DEPARTMENT_CODE      = XDV.DEPARTMENT_CODE(+)
AND   XOH.LEASE_CLASS          = XLCV.LEASE_CLASS_CODE
AND   XOH.LEASE_TYPE           = XLTV.LEASE_TYPE_CODE
AND   XOH.CANCELLATION_TYPE    = XCTV.CANCELLATION_TYPE_CODE(+)
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_CLASS IS                 '���[�X��ʃR�[�h'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_CLASS_NAME IS            '���[�X���'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CONTRACT_NUMBER IS             '�_��ԍ�'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_TYPE IS                  '���[�X�敪'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_TYPE_NAME IS             '���[�X�敪����'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_COMPANY IS               '���[�X��ЃR�[�h'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.PAYMENT_FREQUENCY IS           '�x����'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.PAYMENT_TYPE IS                '�p�x'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CONTRACT_DATE IS               '�_���'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_START_DATE IS            '���[�X�J�n��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_END_DATE IS              '���[�X�I����'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_KIND IS                  '���[�X���'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CONTRACT_LINE_NUM IS           '�_��}��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_INSTALLATION_ADDRESS IS  '����ݒu�ꏊ'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_INSTALLATION_PLACE IS    '����ݒu��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.EXPIRATION_DATE IS             '������'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CANCELLATION_DATE IS           '���r����'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.ORIGINAL_COST IS               '�擾���z'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_CHARGE IS                '���񌎊z���[�X�i�Ŕ��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_TAX_CHARGE IS            '���񌎊z����Ŋz'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_TOTAL_CHARGE IS          '���񌎊z���[�X�i�ō��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.SECOND_CHARGE IS               '�Q��ڈȍ~���z���[�X���i�Ŕ��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.SECOND_TAX_CHARGE IS           '�Q��ڈȍ~���z����Ŋz'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.SECOND_TOTAL_CHARGE IS         '�Q��ڈȍ~���z���[�X�i�ō��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_DEDUCTION IS             '���z���[�X�T���z�i�Ŕ��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_TAX_DEDUCTION IS         '���z���[�X�T������Ŋz'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.FIRST_TOTAL_DEDUCTION IS       '���z���[�X�T���z�i�ō��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_CHARGE IS                '���[�X�����z�i�Ŕ��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_TAX_CHARGE IS            '���[�X����ő��z'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_TOTAL_CHARGE IS          '���[�X�����z�i�ō��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_DEDUCTION IS             '�T���z���z�i�Ŕ��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_TAX_DEDUCTION IS         '�T���z����ő��z'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.GROSS_TOTAL_DEDUCTION IS       '�T���z���z�i�ō��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.DEPARTMENT_CODE IS             '�Ǘ�����R�[�h'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.OWNER_COMPANY IS               '�{��/�H��敪'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.OBJECT_CODE IS                 '�����R�[�h'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CHASSIS_NUMBER IS              '�ԑ�ԍ�'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.RE_LEASE_TIMES IS              '�ă��[�X��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.AGE_TYPE IS                    '�N��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.MODEL IS                       '�@��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.SERIAL_NUMBER IS               '�@��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.MANUFACTURER_NAME IS           '���[�J�[���i�����Җ��j'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.INSTALLATION_ADDRESS IS        '���ݒu�ꏊ'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.INSTALLATION_PLACE IS          '���ݒu��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CANCELLATION_TYPE IS           '���r���敪'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CANCELLATION_TYPE_NAME IS      '���r���敪����'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.BOND_ACCEPTANCE_DATE IS        '�؏���̓�'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.OBJECT_STATUS IS               '�����X�e�[�^�X'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.SEGMENT2_DESC IS              '�Ǘ�����'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_CLASS_CODE IS           '���[�X���'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_COMPANY_CODE IS        '���[�X��ЃR�[�h'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LEASE_COMPANY_NAME IS        '���[�X���'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LAST_UPDATE_DATE IS '�ŏI�X�V��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LAST_UPDATED_BY IS '�ŏI�X�V��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CREATED_BY IS '�쐬��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.CREATION_DATE IS '�쐬��'
/
COMMENT ON COLUMN XXCFF_LEASED_ASSETS_V.LAST_UPDATE_LOGIN IS '�ŏI�X�V���O�C��'
/
COMMENT ON TABLE XXCFF_LEASED_ASSETS_V IS '���[�X���Y�ꗗ��ʃr���['
/
