CREATE OR REPLACE FORCE VIEW XXCFF_OBJ_INS_REFERENCE_V
(
 OBJECT_HEADER_ID           --���������h�c
,HISTORY_NUM                --MAX(�ύX�����m�n)
,GENERATION_DATE            --�ύX��
,OBJECT_CODE                --�����R�[�h
,LEASE_CLASS                --���[�X���
,LEASE_CLASS_NAME          --���[�X��ʖ�
,OWNER_COMPANY              --�{�ЍH��敪
,OWNER_COMPANY_NAME        --�{�ЍH��敪��
,DEPARTMENT_CODE            --�Ǘ�����
,DEPARTMENT_NAME            --�Ǘ����喼
,PO_NUMBER                  --�����ԍ�
,MANUFACTURER_NAME          --���[�J�[��
,MODEL                      --�@��
,SERIAL_NUMBER              --�@��
,AGE_TYPE                   --�N��
,QUANTITY                   --����
,CHASSIS_NUMBER             --�ԑ�ԍ�
,REGISTRATION_NUMBER        --�o�^�ԍ�
,INSTALLATION_PLACE         --���ݒu��
,INSTALLATION_ADDRESS       --���ݒu�ꏊ
,RE_LEASE_FLAG              --�ă��[�X�v
,OBJECT_STATUS              --�����X�e�[�^�X
,OBJECT_STATUS_NAME         --�����X�e�[�^�X��
,LEASE_TYPE                 --���[�X�敪
,LEASE_TYPE_NAME            --���[�X�敪��
,RE_LEASE_TIMES             --�ă��[�X��
,BOND_ACCEPTANCE_FLAG       --�؏���̃t���O
,DESCRIPTION                --�E�v
,FULL_NAME                  --�쐬�Җ�
,CREATED_BY                 --�쐬��
,CREATION_DATE              --�쐬��
,LAST_UPDATED_BY            --�ŏI�X�V��
,LAST_UPDATE_DATE           --�ŏI�X�V��
,LAST_UPDATE_LOGIN          --�ŏI�X�V۸޲�
,CANCELLATION_TYPE          --���敪
,CANCELLATION_TYPE_NAME     --���敪��
,LEASE_COMPANY              --���[�X���
,LEASE_COMPANY_NAME         --���[�X��Ж�
,CONTRACT_NUMBER            --�_��ԍ�
,LEASE_START_DATE           --���[�X�J�n��
,LEASE_END_DATE             --���[�X�I����
,CONTRACT_LINE_NUM          --�_��}��
,LEASE_KIND                 --���[�X���
,LEASE_KIND_NAME           --���[�X��ޖ�
,ESTIMATED_CASH_PRICE       --���ό����w�����z
,SECOND_TOTAL_CHARGE        --2��ڈȍ~�v_���[�X��
,SECOND_TOTAL_DEDUCTION     --2��ڈȍ~�v_�T���z
,GROSS_TOTAL_CHARGE         --���z�v_���[�X��
,FIRST_INSTALLATION_PLACE   --����ݒu��
,FIRST_INSTALLATION_ADDRESS --����ݒu�ꏊ
)
AS 
SELECT XOH.OBJECT_HEADER_ID           --���������h�c
      ,XOH.HISTORY_NUM                --MAX(�ύX�����m�n)
      ,XOH.GENERATION_DATE            --�ύX��
      ,XOH.OBJECT_CODE                --�����R�[�h
      ,XOH.LEASE_CLASS                --���[�X���
      ,XLCV.LEASE_CLASS_NAME          --���[�X��ʖ�
      ,XOH.OWNER_COMPANY              --�{�ЍH��敪
      ,XOCV.OWNER_COMPANY_NAME        --�{�ЍH��敪��
      ,XOH.DEPARTMENT_CODE            --�Ǘ�����
      ,XDV.DEPARTMENT_NAME            --�Ǘ����喼
      ,XOH.PO_NUMBER                  --�����ԍ�
      ,XOH.MANUFACTURER_NAME          --���[�J�[��
      ,XOH.MODEL                      --�@��
      ,XOH.SERIAL_NUMBER              --�@��
      ,XOH.AGE_TYPE                   --�N��
      ,XOH.QUANTITY                   --����
      ,XOH.CHASSIS_NUMBER             --�ԑ�ԍ�
      ,XOH.REGISTRATION_NUMBER        --�o�^�ԍ�
      ,XOH.INSTALLATION_PLACE         --���ݒu��
      ,XOH.INSTALLATION_ADDRESS       --���ݒu�ꏊ
      ,XOH.RE_LEASE_FLAG              --�ă��[�X�v
      ,XOH.OBJECT_STATUS              --�����X�e�[�^�X
      ,XOSV.OBJECT_STATUS_NAME        --�����X�e�[�^�X��
      ,XOH.LEASE_TYPE                 --���[�X�敪
      ,XLTV.LEASE_TYPE_NAME           --���[�X�敪��
      ,XOH.RE_LEASE_TIMES             --�ă��[�X��
      ,XOH.BOND_ACCEPTANCE_FLAG       --�؏���̃t���O
      ,XOH.DESCRIPTION                --�E�v
      ,PPF.FULL_NAME                  --�쐬�Җ�
      ,XOH.CREATED_BY                 --�쐬��
      ,XOH.CREATION_DATE              --�쐬��
      ,XOH.LAST_UPDATED_BY            --�ŏI�X�V��
      ,XOH.LAST_UPDATE_DATE           --�ŏI�X�V��
      ,XOH.LAST_UPDATE_LOGIN          --�ŏI�X�V۸޲�
      ,XOH.CANCELLATION_TYPE          --���敪
      ,XCTV.CANCELLATION_TYPE_NAME    --���敪��
      ,XGK.LEASE_COMPANY              --���[�X���
      ,XLCV.LEASE_COMPANY_NAME        --���[�X��Ж�
      ,XGK.CONTRACT_NUMBER            --�_��ԍ�
      ,XGK.LEASE_START_DATE           --���[�X�J�n��
      ,XGK.LEASE_END_DATE             --���[�X�I����
      ,XGK.CONTRACT_LINE_NUM          --�_��}��
      ,XGK.LEASE_KIND                 --���[�X���
      ,XGK.LEASE_KIND_NAME            --���[�X��ޖ�
      ,XGK.ESTIMATED_CASH_PRICE       --���ό����w�����z
      ,XGK.SECOND_TOTAL_CHARGE        --2��ڈȍ~�v_���[�X��
      ,XGK.SECOND_TOTAL_DEDUCTION     --2��ڈȍ~�v_�T���z
      ,XGK.GROSS_TOTAL_CHARGE         --���z�v_���[�X��
      ,XGK.FIRST_INSTALLATION_PLACE   --����ݒu��
      ,XGK.FIRST_INSTALLATION_ADDRESS --����ݒu�ꏊ
FROM   XXCFF_OBJECT_HISTORIES XOH     --���[�X��������
      ,XXCFF_LEASE_CLASS_V    XLCV    --���[�X��ʃr���[
      ,XXCFF_OWNER_COMPANY_V  XOCV    --�{�ЍH��r���[
      ,XXCFF_DEPARTMENT_V     XDV     --�Ǘ�����r���[
      ,XXCFF_LEASE_COMPANY_V  XLCV    --���[�X��Ѓr���[
      ,XXCFF_LEASE_TYPE_V     XLTV    --���[�X�敪�r���[
      ,XXCFF_OBJECT_STATUS_V  XOSV    --�����X�e�[�^�X�r���[
      ,XXCFF_CANCELLATION_TYPE_V XCTV --���[�X���敪�r���[
        ,(
        SELECT XCH.LEASE_COMPANY              --���[�X���
              ,XCH.CONTRACT_NUMBER            --�_��ԍ�
              ,XCH.LEASE_START_DATE           --���[�X�J�n��
              ,XCH.LEASE_END_DATE             --���[�X�I����
              ,XCH.RE_LEASE_TIMES             --���[�X��
              ,XCL.OBJECT_HEADER_ID
              ,XCL.CONTRACT_LINE_NUM          --�_��}��
              ,XCL.LEASE_KIND                 --���[�X���
              ,XCL.ESTIMATED_CASH_PRICE       --���ό����w�����z
              ,XCL.SECOND_TOTAL_CHARGE        --2��ڈȍ~�v_���[�X��
              ,XCL.SECOND_TOTAL_DEDUCTION     --2��ڈȍ~�v_�T���z
              ,XCL.GROSS_TOTAL_CHARGE         --���z�v_���[�X��
              ,XCL.FIRST_INSTALLATION_PLACE   --����ݒu��
              ,XCL.FIRST_INSTALLATION_ADDRESS --����ݒu�ꏊ
              ,XLKV.LEASE_KIND_NAME           --���[�X��ޖ�
        FROM   XXCFF_CONTRACT_HEADERS XCH     --���[�X�_��
              ,XXCFF_CONTRACT_LINES   XCL     --���[�X�_�񖾍�
              ,XXCFF_LEASE_KIND_V     XLKV    --���[�X��ރr���[
        WHERE  XCH.CONTRACT_HEADER_ID = XCL.CONTRACT_HEADER_ID
        AND    XCL.LEASE_KIND         = XLKV.LEASE_KIND_CODE(+)
        ) XGK
       ,(
        SELECT  FU.USER_ID
               ,PPF.FULL_NAME
        FROM    FND_USER FU
               ,PER_PEOPLE_F PPF
        WHERE   FU.EMPLOYEE_ID = PPF.PERSON_ID
        AND     SYSDATE 
        BETWEEN PPF.EFFECTIVE_START_DATE
        AND     PPF.EFFECTIVE_END_DATE
        )PPF
WHERE  XOH.OBJECT_HEADER_ID   = XGK.OBJECT_HEADER_ID(+)
AND    XGK.LEASE_COMPANY      = XLCV.LEASE_COMPANY_CODE(+)
AND    XOH.RE_LEASE_TIMES     = XGK.RE_LEASE_TIMES(+)
AND    XOH.LEASE_CLASS        = XLCV.LEASE_CLASS_CODE(+)
AND    XOH.OWNER_COMPANY      = XOCV.OWNER_COMPANY_CODE(+)
AND    XOH.DEPARTMENT_CODE    = XDV.DEPARTMENT_CODE(+)
AND    XOH.LEASE_TYPE         = XLTV.LEASE_TYPE_CODE(+)
AND    XOH.OBJECT_STATUS      = XOSV.OBJECT_STATUS_CODE(+)
AND    XOH.CANCELLATION_TYPE  = XCTV.CANCELLATION_TYPE_CODE(+)
AND    PPF.USER_ID(+)            = XOH.CREATED_BY
;
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.OBJECT_HEADER_ID  IS '���������h�c';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.HISTORY_NUM       IS 'MAX(�ύX�����m�n)';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.GENERATION_DATE   IS '�ύX��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.OBJECT_CODE       IS '�����R�[�h';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LEASE_CLASS       IS '���[�X���';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LEASE_CLASS_NAME  IS '���[�X��ʖ�';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.OWNER_COMPANY     IS '�{�ЍH��敪';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.OWNER_COMPANY_NAME IS '�{�ЍH��敪��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.DEPARTMENT_CODE IS '�Ǘ�����';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.DEPARTMENT_NAME IS '�Ǘ����喼';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.PO_NUMBER       IS '�����ԍ�';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.MANUFACTURER_NAME IS '���[�J�[��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.MODEL  IS '�@��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.SERIAL_NUMBER IS '�@��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.AGE_TYPE IS '�N��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.QUANTITY IS '����';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.CHASSIS_NUMBER IS '�ԑ�ԍ�';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.REGISTRATION_NUMBER IS '�o�^�ԍ�';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.INSTALLATION_PLACE  IS '���ݒu��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.INSTALLATION_ADDRESS IS '���ݒu�ꏊ';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.RE_LEASE_FLAG IS '�ă��[�X�v';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.OBJECT_STATUS IS '�����X�e�[�^�X';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.OBJECT_STATUS_NAME IS '�����X�e�[�^�X��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LEASE_TYPE IS '���[�X�敪';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LEASE_TYPE_NAME IS '���[�X�敪��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.RE_LEASE_TIMES IS '�ă��[�X��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.BOND_ACCEPTANCE_FLAG IS '�؏���̃t���O';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.DESCRIPTION IS '�E�v';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.FULL_NAME IS '�쐬�Җ�';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.CREATED_BY IS '�쐬��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.CREATION_DATE IS '�쐬��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LAST_UPDATED_BY IS '�ŏI�X�V��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LAST_UPDATE_DATE IS '�ŏI�X�V��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LAST_UPDATE_LOGIN IS '�ŏI�X�V۸޲�';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.CANCELLATION_TYPE IS '���敪';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.CANCELLATION_TYPE_NAME IS '���敪��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LEASE_COMPANY IS '���[�X���';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LEASE_COMPANY_NAME IS '���[�X��Ж�';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.CONTRACT_NUMBER IS '�_��ԍ�';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LEASE_START_DATE IS '���[�X�J�n��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LEASE_END_DATE IS '���[�X�I����';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.CONTRACT_LINE_NUM IS '�_��}��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LEASE_KIND IS '���[�X���';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.LEASE_KIND_NAME IS '���[�X��ޖ�';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.ESTIMATED_CASH_PRICE IS '���ό����w�����z';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.SECOND_TOTAL_CHARGE IS '2��ڈȍ~�v_���[�X��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.SECOND_TOTAL_DEDUCTION IS '2��ڈȍ~�v_�T���z';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.GROSS_TOTAL_CHARGE IS '���z�v_���[�X��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.FIRST_INSTALLATION_PLACE IS '����ݒu��';
COMMENT ON COLUMN XXCFF_OBJ_INS_REFERENCE_V.FIRST_INSTALLATION_ADDRESS IS '����ݒu�ꏊ';
COMMENT ON TABLE XXCFF_OBJ_INS_REFERENCE_V IS '���[�X���������Ɖ��ʃr���[';
