-- **************************************************************************************
-- Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
--
-- Package Name     : xxwsh930005d(ctl)
-- Description      : HHT���o�Ɏ��уC���^�[�t�F�[�X SQL*Loader����
-- MD.050           : ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�j     T_MD050_BPO_930
-- MD.070           : HHT���o�Ɏ��уC���^�[�t�F�[�X_SQLLoader����  T_MD070_BPO_93E
-- Version          : 1.1
--
-- Change Record
-- ------------- ----- ----------------- ------------------------------------------------
--  Date          Ver.  Editor            Description
-- ------------- ----- ----------------- ------------------------------------------------
--  2008/02/26    1.0   Oracle �Ŗ� ���\  ����쐬
--  2008/05/19    1.1   Oracle �Ŗ� ���\  �����ύX�v��#100�Ή�
--  2008/06/06    1.2   Oracle �y�c �M    �f�[�^�^�C�v�ɒl���ݒ肳��Ȃ��s��Ή�
--  2008/06/11    1.3   Oracle �y�c �M    ���ׂ�HEADER_ID�s��Ή�
-- **************************************************************************************
LOAD DATA
INFILE *
APPEND
INTO TABLE XXWSH_SHIPPING_HEADERS_IF
WHEN(FILLER02 = '10')
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
HEADER_ID                     "APPS.XXWSH_LOADER_ID_FUNC('HEADERS', 'HEADERS', :EOS_DATA_TYPE, :DELIVERY_NO, :ORDER_SOURCE_REF)", -- �w�b�_ID
FILLER01                      POSITION(1),                                    -- ��Ж�
EOS_DATA_TYPE                 POSITION(*),                                    -- �f�[�^���
FILLER02                      POSITION(*),                                    -- �`���p�}��
DELIVERY_NO                   POSITION(*),                                    -- �z��No
ORDER_SOURCE_REF              POSITION(*),                                    -- �˗�No
FILLER03                      POSITION(*),                                    -- �\��
FILLER04                      POSITION(*),                                    -- ���_�R�[�h
FILLER05                      POSITION(*),                                    -- �Ǌ����_����
LOCATION_CODE                 POSITION(*),                                    -- �o�ɑq�ɃR�[�h
FILLER06                      POSITION(*),                                    -- �o�ɑq�ɖ���
SHIP_TO_LOCATION              POSITION(*),                                    -- ���ɑq�ɃR�[�h
FILLER07                      POSITION(*),                                    -- ���ɑq�ɖ���
FREIGHT_CARRIER_CODE          POSITION(*),                                    -- �^���Ǝ҃R�[�h
FILLER08                      POSITION(*),                                    -- �^���ƎҖ�
PARTY_SITE_CODE               POSITION(*),                                    -- �z����R�[�h
FILLER09                      POSITION(*),                                    -- �z���於
SHIPPED_DATE                  POSITION(*)   DATE(10)"YYYY/MM/DD",             -- ����
ARRIVAL_DATE                  POSITION(*)   DATE(10)"YYYY/MM/DD",             -- ����
SHIPPING_METHOD_CODE          POSITION(*),                                    -- �z���敪
FILLER10                      POSITION(*),                                    -- �d��/�e��
FILLER11                      POSITION(*),                                    -- ���ڌ��˗���
COLLECTED_PALLET_QTY          POSITION(*),                                    -- �p���b�g�������
ARRIVAL_TIME_FROM             POSITION(*),                                    -- ���׎��Ԏw��(FROM)
ARRIVAL_TIME_TO               POSITION(*),                                    -- ���׎��Ԏw��(TO)
CUST_PO_NUMBER                POSITION(*),                                    -- �ڋq�����ԍ�
FILLER12                      POSITION(*),                                    -- �E�v
FILLER13                      POSITION(*),                                    -- �X�e�[�^�X
FILLER14                      POSITION(*),                                    -- �^���敪
USED_PALLET_QTY               POSITION(*),                                    -- �p���b�g�g�p����
FILLER15                      POSITION(*),                                    -- �\���@
FILLER16                      POSITION(*),                                    -- �\���A
FILLER17                      POSITION(*),                                    -- �\���B
FILLER18                      POSITION(*),                                    -- �\���C
REPORT_POST_CODE              POSITION(*),                                    -- �񍐕���
CREATED_BY                    CONSTANT 0,                                     -- �쐬��
CREATION_DATE                 SYSDATE,                                        -- �쐬��
LAST_UPDATED_BY               CONSTANT 0,                                     -- �ŏI�X�V��
LAST_UPDATE_DATE              SYSDATE,                                        -- �ŏI�X�V��
LAST_UPDATE_LOGIN             CONSTANT 0,                                     -- �ŏI�X�V���O�C��
REQUEST_ID                    CONSTANT 0,                                     -- �v��ID
PROGRAM_APPLICATION_ID        CONSTANT 0,                                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
PROGRAM_ID                    CONSTANT 0,                                     -- �R���J�����g�E�v���O����ID
PROGRAM_UPDATE_DATE           SYSDATE,                                        -- �v���O�����X�V��
DATA_TYPE                     CONSTANT "40"                                   -- �f�[�^�^�C�v
)
INTO TABLE XXWSH_SHIPPING_LINES_IF
WHEN(FILLER05 = '20')
FIELDS TERMINATED BY ','
TRAILING NULLCOLS
(
ORDERD_ITEM_CODE              POSITION(*),                                    -- �i�ڃR�[�h
FILLER01                      POSITION(*),                                    -- �i�ږ�
FILLER02                      POSITION(*),                                    -- �i�ڒP��
ORDERD_QUANTITY               POSITION(*),                                    -- �i�ڐ���
LOT_NO                        POSITION(*),                                    -- ���b�g�ԍ�
DESIGNATED_PRODUCTION_DATE    POSITION(*)   DATE(10)"YYYY/MM/DD",             -- ������
USE_BY_DATE                   POSITION(*)   DATE(10)"YYYY/MM/DD",             -- �ܖ�����
ORIGINAL_CHARACTER            POSITION(*),                                    -- �ŗL�L��
DETAILED_QUANTITY             POSITION(*),                                    -- ���b�g����
CREATED_BY                    CONSTANT 0,                                     -- �쐬��
CREATION_DATE                 SYSDATE,                                        -- �쐬��
LAST_UPDATED_BY               CONSTANT 0,                                     -- �ŏI�X�V��
LAST_UPDATE_DATE              SYSDATE,                                        -- �ŏI�X�V��
LAST_UPDATE_LOGIN             CONSTANT 0,                                     -- �ŏI�X�V���O�C��
REQUEST_ID                    CONSTANT 0,                                     -- �v��ID
PROGRAM_APPLICATION_ID        CONSTANT 0,                                     -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
PROGRAM_ID                    CONSTANT 0,                                     -- �R���J�����g�E�v���O����ID
PROGRAM_UPDATE_DATE           SYSDATE,                                        -- �v���O�����X�V��
FILLER03                      POSITION(1),                                    -- ��Ж�
FILLER04                      POSITION(*),                                    -- �f�[�^���
FILLER05                      POSITION(*),                                    -- �`���p�}��
FILLER06                      POSITION(*),                                    -- �z��No
FILLER07                      POSITION(*),                                    -- �˗�No
LINE_ID                       "APPS.XXWSH_LOADER_ID_FUNC('LINES', 'LINES', :FILLER04, :FILLER06, :FILLER07)",  -- ����ID
HEADER_ID                     "APPS.XXWSH_LOADER_ID_FUNC('LINES', 'HEADERS', :FILLER04, :FILLER06, :FILLER07)" -- �w�b�_ID
)
