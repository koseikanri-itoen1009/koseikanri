/*************************************************************************
 * 
 * View  Name      : XXSKZ_�݌ɒ���_��{_V
 * Description     : XXSKZ_�݌ɒ���_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK ����    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�݌ɒ���_��{_V
(
 ���o�ɋ敪
,���R�R�[�h
,���R�R�[�h��
,�q�ɃR�[�h
,�ۊǏꏊ�R�[�h
,�ۊǏꏊ��
,�ۊǏꏊ����
,���i�敪
,���i�敪��
,�i�ڋ敪
,�i�ڋ敪��
,�Q�R�[�h
,�i�ڃR�[�h
,�i�ږ�
,�i�ڗ���
,�P��
,���b�gNo
,�����N����
,�ŗL�L��
,�ܖ�����
,�݌ɒ����p�E�v
,�`�[No
,���o�ɓ�
,���ɐ�
,���ɃP�[�X��
,�o�ɐ�
,�o�ɃP�[�X��
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT  ZTIO.inout_kbn                      inout_kbn              -- ���o�ɋ敪
       ,ZTIO.reason_code                    reason_code            -- ���R�R�[�h
       ,FLV01.meaning                       reason_code_name       -- ���R�R�[�h��
       ,ZTIO.whse_code                      whse_code              -- �q�ɃR�[�h
       ,ZTIO.loct_code                      location_code          -- �ۊǏꏊ�R�[�h
       ,XILV.description                    location_name          -- �ۊǏꏊ��
       ,XILV.short_name                     location_s_name        -- �ۊǏꏊ����
       ,XPCV.prod_class_code                prod_class_code        -- ���i�敪
       ,XPCV.prod_class_name                prod_class_name        -- ���i�敪��
       ,XICV.item_class_code                item_class_code        -- �i�ڋ敪
       ,XICV.item_class_name                item_class_name        -- �i�ڋ敪��
       ,XCCV.crowd_code                     crowd_code             -- �Q�R�[�h
       ,XIMV2.item_no                       item_no                -- �i�ڃR�[�h
       ,XIMV2.item_name                     item_name              -- �i�ږ�
       ,XIMV2.item_short_name               item_s_name            -- �i�ڗ���
       ,IIMB.item_um                        item_um                -- �P��
       ,ILM.lot_no                          lot_no                 -- ���b�gNo
       ,ILM.attribute1                      manufacture_date       -- �����N����
       ,ILM.attribute2                      uniqe_sign             -- �ŗL�L��
       ,ILM.attribute3                      expiration_date        -- �ܖ�����
       ,ZTIO.attribute2                     attribute2             -- �݌ɒ����p�E�v
       ,ZTIO.journal_no                     voucher_no             -- �`�[No
       ,ZTIO.tran_date                      standard_date          -- ���o�ɓ�
       ,NVL( ZTIO.stock_quantity, 0)        stock_quantity         -- ���ɐ�
       ,NVL( TRUNC( ZTIO.stock_quantity / XIMV2.num_of_cases ) , 0)
                                            stock_cs_quantity      -- ���ɃP�[�X��
       ,NVL( ZTIO.leaving_quantity, 0)      leaving_quantity       -- �o�ɐ�
       ,NVL( TRUNC( ZTIO.leaving_quantity / XIMV2.num_of_cases ) , 0)
                                            leaving_cs_quantity    -- �o�ɃP�[�X��
       ,FU_CB.user_name                     created_by             -- �쐬��
       ,TO_CHAR( ZTIO.creation_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            creation_date          -- �쐬��
       ,FU_LU.user_name                     last_updated_by        -- �ŏI�X�V��
       ,TO_CHAR( ZTIO.last_update_date, 'YYYY/MM/DD HH24:MI:SS' )
                                            last_update_date       -- �ŏI�X�V��
       ,FU_LL.user_name                     last_update_login      -- �ŏI�X�V���O�C��
  FROM
       (  -- ���� �݌ɒ���(����) ����
           SELECT
                   '����'                             inout_kbn                 -- ���o�ɋ敪(����)
                  ,XRPM.new_div_invent                reason_code               -- ���R�R�[�h
                  ,IJM.journal_no                     journal_no                -- �`�[No
                  ,ITC.whse_code                      whse_code                 -- �q�ɃR�[�h
                  ,ITC.location                       loct_code                 -- �ۊǏꏊ�R�[�h
                  ,ITC.trans_date                     tran_date                 -- ���o�ɓ�
                  ,ITC.item_id                        item_id                   -- �i��ID
                  ,ITC.lot_id                         lot_id                    -- ���b�gID
                  ,IJM.attribute2                     attribute2                -- �݌ɒ����p�E�v
                  ,ITC.trans_qty                      stock_quantity            -- ���ɐ�
                  ,0                                  leaving_quantity          -- �o�ɐ�
                   --WHO�J����
                  ,ITC.created_by                     created_by                -- �쐬��
                  ,ITC.creation_date                  creation_date             -- �쐬��
                  ,ITC.last_updated_by                last_updated_by           -- �ŏI�X�V��
                  ,ITC.last_update_date               last_update_date          -- �ŏI�X�V��
                  ,ITC.last_update_login              last_update_login         -- �ŏI�X�V���O�C��
             FROM
                   xxcmn_rcv_pay_mst                  XRPM                      -- �󕥋敪�A�h�I���}�X�^
                  ,ic_adjs_jnl                        IAJ                       -- OPM�݌ɒ����W���[�i��
                  ,ic_jrnl_mst                        IJM                       -- OPM�W���[�i���}�X�^
                  ,xxcmn_ic_tran_cmp_arc                        ITC              -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
            WHERE
              -- �󕥋敪�A�h�I���}�X�^�̏���
                   XRPM.doc_type           = 'ADJI'
              AND  XRPM.reason_code        <> 'X977'                            -- �����݌�
              AND  XRPM.reason_code        <> 'X988'                            -- �l������
              AND  XRPM.reason_code        <> 'X123'                            -- �ړ����ђ����i�o�Ɂj
              AND  XRPM.reason_code        <> 'X201'                            -- �d����ԕi
              AND  XRPM.rcv_pay_div        = '1'                                -- ���
              AND  XRPM.use_div_invent     = 'Y'
              -- OPM�����݌Ƀg�����U�N�V�����Ƃ̌���
              AND  ITC.doc_type            = XRPM.doc_type
              AND  ITC.reason_code         = XRPM.reason_code
              -- OPM�݌ɒ����W���[�i���Ƃ̌���
              AND  ITC.doc_type            = IAJ.trans_type
              AND  ITC.doc_id              = IAJ.doc_id
              AND  ITC.doc_line            = IAJ.doc_line
              -- OPM�W���[�i���}�X�^�Ƃ̌���
              AND  IAJ.journal_id          = IJM.journal_id
          -- ���� �݌ɒ���(����) END ����
        UNION ALL
          -- ���� �݌ɒ���(�o��) ����
           SELECT
                   '�o��'                             inout_kbn                 -- ���o�ɋ敪(�o��)
                  ,XRPM.new_div_invent                reason_code               -- ���R�R�[�h
                  ,IJM.journal_no                     journal_no                -- �`�[No
                  ,ITC.whse_code                      whse_code                 -- �q�ɃR�[�h
                  ,ITC.location                       loct_code                 -- �ۊǏꏊ�R�[�h
                  ,ITC.trans_date                     tran_date                 -- ���o�ɓ�
                  ,ITC.item_id                        item_id                   -- �i��ID
                  ,ITC.lot_id                         lot_id                    -- ���b�gID
                  ,IJM.attribute2                     attribute2                -- �݌ɒ����p�E�v
                  ,0                                  stock_quantity            -- ���ɐ�
                  ,ITC.trans_qty * -1                 leaving_quantity          -- �o�ɐ�
                   --WHO�J����
                  ,ITC.created_by                     created_by                -- �쐬��
                  ,ITC.creation_date                  creation_date             -- �쐬��
                  ,ITC.last_updated_by                last_updated_by           -- �ŏI�X�V��
                  ,ITC.last_update_date               last_update_date          -- �ŏI�X�V��
                  ,ITC.last_update_login              last_update_login         -- �ŏI�X�V���O�C��
             FROM
                   xxcmn_rcv_pay_mst                  XRPM                      -- �󕥋敪�A�h�I���}�X�^
                  ,ic_adjs_jnl                        IAJ                       -- OPM�݌ɒ����W���[�i��
                  ,ic_jrnl_mst                        IJM                       -- OPM�W���[�i���}�X�^
                  ,xxcmn_ic_tran_cmp_arc                        ITC             -- OPM�����݌Ƀg�����U�N�V�����i�W���j�o�b�N�A�b�v
            WHERE
              --�󕥋敪�A�h�I���}�X�^�̏���
                   XRPM.doc_type          = 'ADJI'
              AND  XRPM.reason_code      <> 'X977'                  -- �����݌�
              AND  XRPM.reason_code      <> 'X123'                  -- �ړ����ђ����i���Ɂj
              AND  XRPM.rcv_pay_div       = '-1'                    -- ���o
              AND  XRPM.use_div_invent    = 'Y'
              --�����݌Ƀg�����U�N�V�����̏���
              AND  ITC.doc_type           = XRPM.doc_type
              AND  ITC.reason_code        = XRPM.reason_code
              --�݌ɒ����W���[�i���̎擾
              AND  ITC.doc_type           = IAJ.trans_type
              AND  ITC.doc_id             = IAJ.doc_id
              AND  ITC.doc_line           = IAJ.doc_line
              --�W���[�i���}�X�^�̎擾
              AND  IAJ.journal_id         = IJM.journal_id
          --���� �݌ɒ���(�o��) END ����
        )                                             ZTIO
       ,xxskz_item_locations_v                        XILV                      -- OPM�ۊǏꏊ���VIEW
       ,xxskz_prod_class_v                            XPCV                      -- ���i�敪�擾VIEW
       ,xxskz_item_class_v                            XICV                      -- �i�ڋ敪�擾VIEW
       ,xxskz_crowd_code_v                            XCCV                      -- �Q�R�[�h�擾VIEW
       ,xxskz_item_mst2_v                             XIMV2                     -- OPM�i�ڏ��VIEW2
       ,ic_item_mst_b                                 IIMB                      -- OPM�i�ڃ}�X�^
       ,ic_lots_mst                                   ILM                       -- ���b�g�}�X�^
       ,fnd_user                                      FU_CB                     -- ���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                                      FU_LU                     -- ���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                                      FU_LL                     -- ���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins                                    FL_LL                     -- ���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_lookup_values                             FLV01                     -- �N�C�b�N�R�[�h(���R�R�[�h���̎擾�p)
 WHERE
   -- OPM�ۊǏꏊ���擾
        ZTIO.loct_code                                = XILV.segment1(+)
   -- �i�ڃJ�e�S�����擾����
   AND  ZTIO.item_id                                  = XPCV.item_id(+)
   AND  ZTIO.item_id                                  = XICV.item_id(+)
   AND  ZTIO.item_id                                  = XCCV.item_id(+)
   -- OPM�i�ڏ��擾
   AND  ZTIO.item_id                                  = XIMV2.item_id(+)
   AND  ZTIO.tran_date                               >= XIMV2.start_date_active(+)
   AND  ZTIO.tran_date                               <= XIMV2.end_date_active(+)
   -- OPM�i�ڃ}�X�^���擾
   AND  ZTIO.item_id                                  = IIMB.item_id(+)
   -- OPM���b�g�}�X�^�擾
   AND  ZTIO.item_id                                  = ILM.item_id(+)
   AND  ZTIO.lot_id                                   = ILM.lot_id(+)
   -- WHO�J�����擾
   AND  ZTIO.created_by                               = FU_CB.user_id(+)
   AND  ZTIO.last_updated_by                          = FU_LU.user_id(+)
   AND  ZTIO.last_update_login                        = FL_LL.login_id(+)
   AND  FL_LL.user_id                                 = FU_LL.user_id(+)
   -- �N�C�b�N�R�[�h(���R�R�[�h�擾)
   AND  FLV01.lookup_type(+)                          = 'XXCMN_NEW_DIVISION'
   AND  FLV01.language(+)                             = 'JA'
   AND  FLV01.lookup_code(+)                          = ZTIO.reason_code
/
COMMENT ON TABLE APPS.XXSKZ_�݌ɒ���_��{_V IS 'SKYLINK�p�݌ɒ����i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.���o�ɋ敪                    IS '���o�ɋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.���R�R�[�h                    IS '���R�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.���R�R�[�h��                  IS '���R�R�[�h��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�q�ɃR�[�h                    IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�ۊǏꏊ�R�[�h                IS '�ۊǏꏊ�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�ۊǏꏊ��                    IS '�ۊǏꏊ��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�ۊǏꏊ����                  IS '�ۊǏꏊ����'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.���i�敪                      IS '���i�敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.���i�敪��                    IS '���i�敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�i�ڋ敪                      IS '�i�ڋ敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�i�ڋ敪��                    IS '�i�ڋ敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�Q�R�[�h                      IS '�Q�R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�i�ڃR�[�h                    IS '�i�ڃR�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�i�ږ�                        IS '�i�ږ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�i�ڗ���                      IS '�i�ڗ���'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�P��                          IS '�P��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.���b�gNo                      IS '���b�gNo'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�����N����                    IS '�����N����'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�ŗL�L��                      IS '�ŗL�L��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�ܖ�����                      IS '�ܖ�����'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�݌ɒ����p�E�v                IS '�݌ɒ����p�E�v'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�`�[No                        IS '�`�[No'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.���o�ɓ�                      IS '���o�ɓ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.���ɐ�                        IS '���ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.���ɃP�[�X��                  IS '���ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�o�ɐ�                        IS '�o�ɐ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�o�ɃP�[�X��                  IS '�o�ɃP�[�X��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�쐬��                        IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�쐬��                        IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�ŏI�X�V��                    IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�ŏI�X�V��                    IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�݌ɒ���_��{_V.�ŏI�X�V���O�C��              IS '�ŏI�X�V���O�C��'
/
