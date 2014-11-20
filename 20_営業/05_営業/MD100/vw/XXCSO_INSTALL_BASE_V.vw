/*************************************************************************
 * 
 * VIEW Name       : XXCSO_INSTALL_BASE_V
 * Description     : ���ʗp�F�����}�X�^�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 *  2009/03/11    1.1  N.Yabuki      �挎�����ځi�R���ځj��ǉ�
 *  2009/03/25    1.2  S.Kayahara    86�s�ډ��s�폜
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_INSTALL_BASE_V
(
 INSTANCE_ID
,INSTANCE_NUMBER
,INSTALL_CODE
,INSTANCE_TYPE_CODE
,INSTANCE_STATUS_ID
,INSTALL_DATE
,ACTIVE_START_DATE
,VENDOR_MODEL
,VENDOR_NUMBER
,FIRST_INSTALL_DATE
,OP_REQUEST_FLAG
,NEW_OLD_FLAG
,INSTALL_PARTY_ID
,INSTALL_ACCOUNT_ID
,QUANTITY
,ACCOUNTING_CLASS_CODE
,INVENTORY_ITEM_ID
,OBJECT_VERSION_NUMBER
,COUNT_NO
,CHIKU_CD
,SAGYOUGAISYA_CD
,JIGYOUSYO_CD
,DEN_NO
,JOB_KBN
,SINTYOKU_KBN
,YOTEI_DT
,KANRYO_DT
,SAGYO_LEVEL
,DEN_NO2
,JOB_KBN2
,SINTYOKU_KBN2
,JOTAI_KBN1
,JOTAI_KBN2
,JOTAI_KBN3
,NYUKO_DT
,HIKISAKIGAISYA_CD
,HIKISAKIJIGYOSYO_CD
,SETTI_TANTO
,SETTI_TEL1
,SETTI_TEL2
,SETTI_TEL3
,HAIKIKESSAI_DT
,TENHAI_TANTO
,TENHAI_DEN_NO
,SYOYU_CD
,TENHAI_FLG
,KANRYO_KBN
,SAKUJO_FLG
,VEN_KYAKU_LAST
,VEN_TASYA_CD01
,VEN_TASYA_DAISU01
,VEN_TASYA_CD02
,VEN_TASYA_DAISU02
,VEN_TASYA_CD03
,VEN_TASYA_DAISU03
,VEN_TASYA_CD04
,VEN_TASYA_DAISU04
,VEN_TASYA_CD05
,VEN_TASYA_DAISU05
,VEN_HAIKI_FLG
,VEN_SISAN_KBN
,VEN_KOBAI_YMD
,VEN_KOBAI_KG
,SAFTY_LEVEL
,LEASE_KBN
,LAST_INST_CUST_CODE
,LAST_JOTAI_KBN
,LAST_YEAR_MONTH
)
AS
SELECT
 cii.INSTANCE_ID
,cii.INSTANCE_NUMBER
,cii.EXTERNAL_REFERENCE
,cii.INSTANCE_TYPE_CODE
,cii.INSTANCE_STATUS_ID
,cii.INSTALL_DATE
,cii.ACTIVE_START_DATE
,cii.ATTRIBUTE1
,cii.ATTRIBUTE2
,cii.ATTRIBUTE3
,cii.ATTRIBUTE4
,cii.ATTRIBUTE5
,cii.OWNER_PARTY_ID
,cii.OWNER_PARTY_ACCOUNT_ID
,cii.QUANTITY
,cii.ACCOUNTING_CLASS_CODE
,cii.INVENTORY_ITEM_ID
,cii.OBJECT_VERSION_NUMBER
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'COUNT_NO')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'CHIKU_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SAGYOUGAISYA_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JIGYOUSYO_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'DEN_NO')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JOB_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SINTYOKU_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'YOTEI_DT')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'KANRYO_DT')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SAGYO_LEVEL')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'DEN_NO2')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JOB_KBN2')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SINTYOKU_KBN2')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JOTAI_KBN1')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JOTAI_KBN2')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'JOTAI_KBN3')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'NYUKO_DT')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'HIKISAKIGAISYA_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'HIKISAKIJIGYOSYO_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SETTI_TANTO')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SETTI_TEL1')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SETTI_TEL2')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SETTI_TEL3')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'HAIKIKESSAI_DT')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'TENHAI_TANTO')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'TENHAI_DEN_NO')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SYOYU_CD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'TENHAI_FLG')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'KANRYO_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SAKUJO_FLG')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_KYAKU_LAST')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_CD01')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_DAISU01')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_CD02')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_DAISU02')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_CD03')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_DAISU03')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_CD04')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_DAISU04')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_CD05')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_TASYA_DAISU05')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_HAIKI_FLG')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_SISAN_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_KOBAI_YMD')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'VEN_KOBAI_KG')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'SAFTY_LEVEL')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'LEASE_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'LAST_INST_CUST_CODE')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'LAST_JOTAI_KBN')
,xxcso_ib_common_pkg.get_ib_ext_attribs(cii.instance_id,'LAST_YEAR_MONTH')
FROM
 CSI_ITEM_INSTANCES cii
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTANCE_ID IS '�C���X�^���XID';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTANCE_NUMBER IS '�C���X�^���X�ԍ�';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTALL_CODE IS '�����R�[�h';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTANCE_TYPE_CODE IS '�@��敪';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTANCE_STATUS_ID IS '�X�e�[�^�XID';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTALL_DATE IS '������';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.ACTIVE_START_DATE IS '�J�n��';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VENDOR_MODEL IS '�@��';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VENDOR_NUMBER IS '�@��';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.FIRST_INSTALL_DATE IS '����ݒu��';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.OP_REQUEST_FLAG IS '��ƈ˗����t���O';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.NEW_OLD_FLAG IS '�V�Ñ�t���O';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTALL_PARTY_ID IS '�ݒu��p�[�e�BID';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INSTALL_ACCOUNT_ID IS '�ݒu��A�J�E���gID';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.QUANTITY IS '����';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.ACCOUNTING_CLASS_CODE IS '��v����';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.INVENTORY_ITEM_ID IS '�i��ID';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.OBJECT_VERSION_NUMBER IS '�I�u�W�F�N�g�o�[�W�����ԍ�';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.COUNT_NO IS '�J�E���^�[No.';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.CHIKU_CD IS '�n��R�[�h';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SAGYOUGAISYA_CD IS '��Ɖ�ЃR�[�h';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JIGYOUSYO_CD IS '���Ə��R�[�h';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.DEN_NO IS '�ŏI��Ɠ`�[No.';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JOB_KBN IS '�ŏI��Ƌ敪';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SINTYOKU_KBN IS '�ŏI��Ɛi��';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.YOTEI_DT IS '�ŏI��Ɗ����\���';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.KANRYO_DT IS '�ŏI��Ɗ�����';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SAGYO_LEVEL IS '�ŏI�������e';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.DEN_NO2 IS '�ŏI�ݒu�`�[No.';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JOB_KBN2 IS '�ŏI�ݒu�敪';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SINTYOKU_KBN2 IS '�ŏI�ݒu�i��';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JOTAI_KBN1 IS '�@����1�i�ғ���ԁj';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JOTAI_KBN2 IS '�@����2�i��ԏڍׁj';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.JOTAI_KBN3 IS '�@����3�i�p�����j';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.NYUKO_DT IS '���ɓ�';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.HIKISAKIGAISYA_CD IS '���g��ЃR�[�h';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.HIKISAKIJIGYOSYO_CD IS '���g���Ə��R�[�h';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SETTI_TANTO IS '�ݒu��S���Җ�';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SETTI_TEL1 IS '�ݒu��TEL1';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SETTI_TEL2 IS '�ݒu��TEL2';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SETTI_TEL3 IS '�ݒu��TEL3';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.HAIKIKESSAI_DT IS '�p�����ٓ�';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.TENHAI_TANTO IS '�]���p���Ǝ�';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.TENHAI_DEN_NO IS '�]���p���`�[��';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SYOYU_CD IS '���L��';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.TENHAI_FLG IS '�]���p���󋵃t���O';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.KANRYO_KBN IS '�]�������敪';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SAKUJO_FLG IS '�폜�t���O';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_KYAKU_LAST IS '�ŏI�ڋq�R�[�h';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_CD01 IS '���ЃR�[�h�P';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_DAISU01 IS '���Б䐔�P';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_CD02 IS '���ЃR�[�h�Q';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_DAISU02 IS '���Б䐔�Q';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_CD03 IS '���ЃR�[�h�R';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_DAISU03 IS '���Б䐔�R';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_CD04 IS '���ЃR�[�h�S';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_DAISU04 IS '���Б䐔�S';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_CD05 IS '���ЃR�[�h�T';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_TASYA_DAISU05 IS '���Б䐔�T';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_HAIKI_FLG IS '�p���t���O';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_SISAN_KBN IS '���Y�敪';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_KOBAI_YMD IS '�w�����t';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.VEN_KOBAI_KG IS '�w�����z';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.SAFTY_LEVEL IS '���S�ݒu�';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.LEASE_KBN IS '���[�X�敪';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.LAST_INST_CUST_CODE IS '�挎���ݒu��ڋq�R�[�h';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.LAST_JOTAI_KBN IS '�挎���@����';
COMMENT ON COLUMN XXCSO_INSTALL_BASE_V.LAST_YEAR_MONTH IS '�挎���N��';
COMMENT ON TABLE XXCSO_INSTALL_BASE_V IS '�����}�X�^�r���[';
