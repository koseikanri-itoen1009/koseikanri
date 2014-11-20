CREATE OR REPLACE PACKAGE BODY xxcmn790004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn790004c(body)
 * Description      : ���ی������֏���
 * MD.050           : ���b�g�ʎ��ی����v�Z T_MD050_BPO_790
 * MD.070           : ���ی������֏��� T_MD070_BPO_79D
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_lot_cost           ���b�g�ʌ����f�[�^���o����(D-1)
 *  upd_table_api          OPM���b�g�}�X�^�X�V����(D-2)
 *  get_data_dump          �f�[�^�_���v�擾����
 *  put_success_dump       �����f�[�^�_���v�o�͏���
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/2/20     1.0   R.Matusita       �V�K�쐬
 *  2008/04/25    1.1   Marushita        TE080_BPO_790 �s�ID 2,3
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  gv_msg_comma     CONSTANT VARCHAR2(3) := ',';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  lock_expt                 EXCEPTION;     -- ���b�N�擾��O
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);   -- ���b�N�擾��O
--
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name       CONSTANT VARCHAR2(100)  := 'xxcmn790004c'; -- �p�b�P�[�W��
--
  gv_xxcmn          CONSTANT VARCHAR2(100)  := 'XXCMN';        -- ���W���[�����ȗ��FXXCMN�}�X�^����
--
  -- ���b�Z�[�W
  gv_msg_xxcmn10146 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10146';  
                                            -- ���b�Z�[�W�F���b�N�擾�G���[
  gv_msg_xxcmn10036 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-10036';
                                            -- ���b�Z�[�W�F�f�[�^�擾�G���[
  gv_msg_xxcmn00005 CONSTANT VARCHAR2(100)  := 'APP-XXCMN-00005';  
                                            -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �X�V�pPL/SQL�\�^
  TYPE item_id_ttype    IS TABLE OF xxcmn_lot_cost.item_id%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �i��ID
  TYPE item_code_ttype  IS TABLE OF xxcmn_lot_cost.item_code%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �i�ڃR�[�h
  TYPE lot_id_ttype     IS TABLE OF xxcmn_lot_cost.lot_id%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ���b�gID
  TYPE lot_num_ttype    IS TABLE OF xxcmn_lot_cost.lot_num%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- ���b�gNo
  TYPE trans_qty_ttype  IS TABLE OF xxcmn_lot_cost.trans_qty%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �������
  TYPE  attribute1_ttype IS TABLE OF ic_lots_mst.attribute1%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP
  TYPE  attribute2_ttype IS TABLE OF ic_lots_mst.attribute2%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ
  TYPE  attribute3_ttype IS TABLE OF ic_lots_mst.attribute3%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂR
  TYPE  attribute4_ttype IS TABLE OF ic_lots_mst.attribute4%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂS
  TYPE  attribute5_ttype IS TABLE OF ic_lots_mst.attribute5%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂT
  TYPE  attribute6_ttype IS TABLE OF ic_lots_mst.attribute6%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂU
  TYPE unit_price_ttype IS TABLE OF xxcmn_lot_cost.unit_ploce%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �P��
  TYPE  attribute8_ttype IS TABLE OF ic_lots_mst.attribute8%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂW
  TYPE  attribute9_ttype IS TABLE OF ic_lots_mst.attribute9%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂX
  TYPE attribute10_ttype IS TABLE OF ic_lots_mst.attribute10%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP�O
  TYPE attribute11_ttype IS TABLE OF ic_lots_mst.attribute11%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP�P
  TYPE attribute12_ttype IS TABLE OF ic_lots_mst.attribute12%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP�Q
  TYPE attribute13_ttype IS TABLE OF ic_lots_mst.attribute13%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP�R
  TYPE attribute14_ttype IS TABLE OF ic_lots_mst.attribute14%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP�S
  TYPE attribute15_ttype IS TABLE OF ic_lots_mst.attribute15%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP�T
  TYPE attribute16_ttype IS TABLE OF ic_lots_mst.attribute16%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP�U
  TYPE attribute17_ttype IS TABLE OF ic_lots_mst.attribute17%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP�V
  TYPE attribute18_ttype IS TABLE OF ic_lots_mst.attribute18%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP�W
  TYPE attribute19_ttype IS TABLE OF ic_lots_mst.attribute19%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂP�X
  TYPE attribute20_ttype IS TABLE OF ic_lots_mst.attribute20%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ�O
  TYPE attribute21_ttype IS TABLE OF ic_lots_mst.attribute21%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ�P
  TYPE attribute22_ttype IS TABLE OF ic_lots_mst.attribute22%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ�Q
  TYPE attribute23_ttype IS TABLE OF ic_lots_mst.attribute23%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ�R
  TYPE attribute24_ttype IS TABLE OF ic_lots_mst.attribute24%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ�S
  TYPE attribute25_ttype IS TABLE OF ic_lots_mst.attribute25%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ�T
  TYPE attribute26_ttype IS TABLE OF ic_lots_mst.attribute26%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ�U
  TYPE attribute27_ttype IS TABLE OF ic_lots_mst.attribute27%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ�V
  TYPE attribute28_ttype IS TABLE OF ic_lots_mst.attribute28%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ�W
  TYPE attribute29_ttype IS TABLE OF ic_lots_mst.attribute29%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂQ�X
  TYPE attribute30_ttype IS TABLE OF ic_lots_mst.attribute30%TYPE INDEX BY BINARY_INTEGER;
                                                                           -- �c�e�e���ڂR�O

--
  -- �X�V�pPL/SQL�\
  gt_item_id_upd_tab     item_id_ttype;      -- �i��ID
  gt_item_code_upd_tab   item_code_ttype;    -- �i�ڃR�[�h
  gt_lot_id_upd_tab      lot_id_ttype;       -- ���b�gID
  gt_lot_num_upd_tab     lot_num_ttype;      -- ���b�gNo
  gt_trans_qty_upd_tab   trans_qty_ttype;    -- �������
  gt_attribute1_upd_tab  attribute1_ttype;   -- �c�e�e���ڂP
  gt_attribute2_upd_tab  attribute2_ttype;   -- �c�e�e���ڂQ
  gt_attribute3_upd_tab  attribute3_ttype;   -- �c�e�e���ڂR
  gt_attribute4_upd_tab  attribute4_ttype;   -- �c�e�e���ڂS
  gt_attribute5_upd_tab  attribute5_ttype;   -- �c�e�e���ڂT
  gt_attribute6_upd_tab  attribute6_ttype;   -- �c�e�e���ڂU
  gt_unit_price_upd_tab  unit_price_ttype;   -- �P��
  gt_attribute8_upd_tab  attribute8_ttype;   -- �c�e�e���ڂW
  gt_attribute9_upd_tab  attribute9_ttype;   -- �c�e�e���ڂX
  gt_attribute10_upd_tab attribute10_ttype;  -- �c�e�e���ڂP�O
  gt_attribute11_upd_tab attribute11_ttype;  -- �c�e�e���ڂP�P
  gt_attribute12_upd_tab attribute12_ttype;  -- �c�e�e���ڂP�Q
  gt_attribute13_upd_tab attribute13_ttype;  -- �c�e�e���ڂP�R
  gt_attribute14_upd_tab attribute14_ttype;  -- �c�e�e���ڂP�S
  gt_attribute15_upd_tab attribute15_ttype;  -- �c�e�e���ڂP�T
  gt_attribute16_upd_tab attribute16_ttype;  -- �c�e�e���ڂP�U
  gt_attribute17_upd_tab attribute17_ttype;  -- �c�e�e���ڂP�V
  gt_attribute18_upd_tab attribute18_ttype;  -- �c�e�e���ڂP�W
  gt_attribute19_upd_tab attribute19_ttype;  -- �c�e�e���ڂP�X
  gt_attribute20_upd_tab attribute20_ttype;  -- �c�e�e���ڂQ�O
  gt_attribute21_upd_tab attribute21_ttype;  -- �c�e�e���ڂQ�P
  gt_attribute22_upd_tab attribute22_ttype;  -- �c�e�e���ڂQ�Q
  gt_attribute23_upd_tab attribute23_ttype;  -- �c�e�e���ڂQ�R
  gt_attribute24_upd_tab attribute24_ttype;  -- �c�e�e���ڂQ�S
  gt_attribute25_upd_tab attribute25_ttype;  -- �c�e�e���ڂQ�T
  gt_attribute26_upd_tab attribute26_ttype;  -- �c�e�e���ڂQ�U
  gt_attribute27_upd_tab attribute27_ttype;  -- �c�e�e���ڂQ�V
  gt_attribute28_upd_tab attribute28_ttype;  -- �c�e�e���ڂQ�W
  gt_attribute29_upd_tab attribute29_ttype;  -- �c�e�e���ڂQ�X
  gt_attribute30_upd_tab attribute30_ttype;  -- �c�e�e���ڂR�O
--
  -- ���b�g�ʌ����f�[�^���i�[���郌�R�[�h
  TYPE lot_data_rec IS RECORD(
    item_id     xxcmn_lot_cost.item_id%TYPE,        -- �i��ID
    item_code   xxcmn_lot_cost.item_code%TYPE,      -- �i�ڃR�[�h
    lot_id      xxcmn_lot_cost.lot_id%TYPE,         -- ���b�gID
    lot_num     xxcmn_lot_cost.lot_num%TYPE,        -- ���b�gNo
    trans_qty   xxcmn_lot_cost.trans_qty%TYPE,      -- �������
    attribute1  ic_lots_mst.attribute1%TYPE,        -- �c�e�e���ڂP
    attribute2  ic_lots_mst.attribute2%TYPE,        -- �c�e�e���ڂQ
    attribute3  ic_lots_mst.attribute3%TYPE,        -- �c�e�e���ڂR
    attribute4  ic_lots_mst.attribute4%TYPE,        -- �c�e�e���ڂS
    attribute5  ic_lots_mst.attribute5%TYPE,        -- �c�e�e���ڂT
    attribute6  ic_lots_mst.attribute6%TYPE,        -- �c�e�e���ڂU
    unit_price  xxcmn_lot_cost.unit_ploce%TYPE,     -- �P��
    attribute8  ic_lots_mst.attribute8%TYPE,        -- �c�e�e���ڂW
    attribute9  ic_lots_mst.attribute9%TYPE,        -- �c�e�e���ڂX
    attribute10 ic_lots_mst.attribute10%TYPE,       -- �c�e�e���ڂP�O
    attribute11 ic_lots_mst.attribute11%TYPE,       -- �c�e�e���ڂP�P
    attribute12 ic_lots_mst.attribute12%TYPE,       -- �c�e�e���ڂP�Q
    attribute13 ic_lots_mst.attribute13%TYPE,       -- �c�e�e���ڂP�R
    attribute14 ic_lots_mst.attribute14%TYPE,       -- �c�e�e���ڂP�S
    attribute15 ic_lots_mst.attribute15%TYPE,       -- �c�e�e���ڂP�T
    attribute16 ic_lots_mst.attribute16%TYPE,       -- �c�e�e���ڂP�U
    attribute17 ic_lots_mst.attribute17%TYPE,       -- �c�e�e���ڂP�V
    attribute18 ic_lots_mst.attribute18%TYPE,       -- �c�e�e���ڂP�W
    attribute19 ic_lots_mst.attribute19%TYPE,       -- �c�e�e���ڂP�X
    attribute20 ic_lots_mst.attribute20%TYPE,       -- �c�e�e���ڂQ�O
    attribute21 ic_lots_mst.attribute21%TYPE,       -- �c�e�e���ڂQ�P
    attribute22 ic_lots_mst.attribute22%TYPE,       -- �c�e�e���ڂQ�Q
    attribute23 ic_lots_mst.attribute23%TYPE,       -- �c�e�e���ڂQ�R
    attribute24 ic_lots_mst.attribute24%TYPE,       -- �c�e�e���ڂQ�S
    attribute25 ic_lots_mst.attribute25%TYPE,       -- �c�e�e���ڂQ�T
    attribute26 ic_lots_mst.attribute26%TYPE,       -- �c�e�e���ڂQ�U
    attribute27 ic_lots_mst.attribute27%TYPE,       -- �c�e�e���ڂQ�V
    attribute28 ic_lots_mst.attribute28%TYPE,       -- �c�e�e���ڂQ�W
    attribute29 ic_lots_mst.attribute29%TYPE,       -- �c�e�e���ڂQ�X
    attribute30 ic_lots_mst.attribute30%TYPE        -- �c�e�e���ڂR�O
  );
--
  -- ���̓f�[�^�_���v�pPL/SQL�\�^
  TYPE msg_ttype      IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_upd_cnt          NUMBER DEFAULT 0;      -- �X�V����
--
  gv_msg_kbn          CONSTANT VARCHAR2(5)  := 'XXCMN';
  --���b�Z�[�W�ԍ�
  gv_msg_80a_016      CONSTANT VARCHAR2(15) := 'APP-XXCMN-10018';  --API�G���[(�R���J�����g)
  --�g�[�N��
  gv_tkn_api_name     CONSTANT VARCHAR2(15) := 'API_NAME';
--
  TYPE lot_data_tbl IS TABLE OF lot_data_rec INDEX BY PLS_INTEGER;
--
  gt_lot_data_tbl     lot_data_tbl;           -- �����z��̒�`
--
  gd_date     DATE;           -- SYSDATE�i�[
  gn_user_id  NUMBER(15,0);   -- USER_ID�i�[
--
  /**********************************************************************************
   * Procedure Name   : get_lot_cost
   * Description      : ���b�g�ʌ����f�[�^���o����(D-1)
   ***********************************************************************************/
  PROCEDURE get_lot_cost(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lot_cost'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    ln_cnt   NUMBER DEFAULT 0;
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
   /**********************************************************************************
   * �f�[�^�ҏW����
   ***********************************************************************************/
--
    BEGIN
    -- ���b�g�ʌ����i�A�h�I���j�e�[�u���ɓ���i�ځE���ꃍ�b�g�A
    -- �P���Ⴂ�̃f�[�^�����݂���f�[�^
      SELECT  xlc.item_id               item_id         -- ���b�g�ʌ����i�A�h�I���j�i��ID
            , xlc.item_code             item_code       -- ���b�g�ʌ����i�A�h�I���j�i�ڃR�[�h
            , xlc.lot_id                lot_id          -- ���b�g�ʌ����i�A�h�I���j���b�gID
            , xlc.lot_num               lot_num         -- ���b�g�ʌ����i�A�h�I���j���b�gNo
            , NVL(xlc.trans_qty,0)      trans_qty       -- ���b�g�ʌ����i�A�h�I���j�������
            , ilm.attribute1            attribute1      -- OPM���b�g�}�X�^ �c�e�e���ڂP
            , ilm.attribute2            attribute2      -- OPM���b�g�}�X�^ �c�e�e���ڂQ
            , ilm.attribute3            attribute3      -- OPM���b�g�}�X�^ �c�e�e���ڂR
            , ilm.attribute4            attribute4      -- OPM���b�g�}�X�^ �c�e�e���ڂS
            , ilm.attribute5            attribute5      -- OPM���b�g�}�X�^ �c�e�e���ڂT
            , ilm.attribute6            attribute6      -- OPM���b�g�}�X�^ �c�e�e���ڂU
            , NVL(xlc.unit_ploce,0)     price           -- ���b�g�ʌ����i�A�h�I���j�P��
            , ilm.attribute8            attribute8      -- OPM���b�g�}�X�^ �c�e�e���ڂW
            , ilm.attribute9            attribute9      -- OPM���b�g�}�X�^ �c�e�e���ڂX
            , ilm.attribute10           attribute10     -- OPM���b�g�}�X�^ �c�e�e���ڂP�O
            , ilm.attribute11           attribute11     -- OPM���b�g�}�X�^ �c�e�e���ڂP�P
            , ilm.attribute12           attribute12     -- OPM���b�g�}�X�^ �c�e�e���ڂP�Q
            , ilm.attribute13           attribute13     -- OPM���b�g�}�X�^ �c�e�e���ڂP�R
            , ilm.attribute14           attribute14     -- OPM���b�g�}�X�^ �c�e�e���ڂP�S
            , ilm.attribute15           attribute15     -- OPM���b�g�}�X�^ �c�e�e���ڂP�T
            , ilm.attribute16           attribute16     -- OPM���b�g�}�X�^ �c�e�e���ڂP�U
            , ilm.attribute17           attribute17     -- OPM���b�g�}�X�^ �c�e�e���ڂP�V
            , ilm.attribute18           attribute18     -- OPM���b�g�}�X�^ �c�e�e���ڂP�W
            , ilm.attribute19           attribute19     -- OPM���b�g�}�X�^ �c�e�e���ڂP�X
            , ilm.attribute20           attribute20     -- OPM���b�g�}�X�^ �c�e�e���ڂQ�O
            , ilm.attribute21           attribute21     -- OPM���b�g�}�X�^ �c�e�e���ڂQ�P
            , ilm.attribute22           attribute22     -- OPM���b�g�}�X�^ �c�e�e���ڂQ�Q
            , ilm.attribute23           attribute23     -- OPM���b�g�}�X�^ �c�e�e���ڂQ�R
            , ilm.attribute24           attribute24     -- OPM���b�g�}�X�^ �c�e�e���ڂQ�S
            , ilm.attribute25           attribute25     -- OPM���b�g�}�X�^ �c�e�e���ڂQ�T
            , ilm.attribute26           attribute26     -- OPM���b�g�}�X�^ �c�e�e���ڂQ�U
            , ilm.attribute27           attribute27     -- OPM���b�g�}�X�^ �c�e�e���ڂQ�V
            , ilm.attribute28           attribute28     -- OPM���b�g�}�X�^ �c�e�e���ڂQ�W
            , ilm.attribute29           attribute29     -- OPM���b�g�}�X�^ �c�e�e���ڂQ�X
            , ilm.attribute30           attribute30     -- OPM���b�g�}�X�^ �c�e�e���ڂR�O
      BULK COLLECT INTO gt_lot_data_tbl
      FROM    xxcmn_lot_cost xlc                        -- ���b�g�ʌ����i�A�h�I���j
            , ic_lots_mst    ilm                        -- OPM���b�g�}�X�^
      WHERE xlc.item_id    =  ilm.item_id
      AND   xlc.lot_id     =  ilm.lot_id
      AND   xlc.unit_ploce <> TO_NUMBER(NVL(ilm.attribute7,'0'))
      FOR UPDATE OF ilm.item_id
                  , ilm.lot_id
      NOWAIT
      ;
--
    EXCEPTION
      --*** ���b�N�擾�G���[ ***
      WHEN lock_expt THEN
        -- �G���[���b�Z�[�W�擾
        lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                      gv_xxcmn          -- ���W���[�������́FXXCMN �}�X�^�E�o������
                     ,gv_msg_xxcmn10146 -- ���b�Z�[�W�F���b�N�擾�G���[
                     ),1,5000);
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- �X�V�p�f�[�^��PL/SQL�\�ɃZ�b�g
    -- ========================================
    <<upd_data_loop>>
    FOR ln_cnt IN 1 .. NVL(gt_lot_data_tbl.LAST,0) LOOP
        -- �f�[�^�J�E���g
      gn_upd_cnt :=  gn_upd_cnt + 1;
        -- �����������J�E���g
      gn_target_cnt := gn_target_cnt + 1;
--
      -- �l�Z�b�g
      gt_item_id_upd_tab(gn_upd_cnt)     := gt_lot_data_tbl(ln_cnt).item_id;     -- �i��ID
      gt_item_code_upd_tab(gn_upd_cnt)   := gt_lot_data_tbl(ln_cnt).item_code;   -- �i�ڃR�[�h
      gt_lot_id_upd_tab(gn_upd_cnt)      := gt_lot_data_tbl(ln_cnt).lot_id;      -- ���b�gID
      gt_lot_num_upd_tab(gn_upd_cnt)     := gt_lot_data_tbl(ln_cnt).lot_num;     -- ���b�gNo
      gt_trans_qty_upd_tab(gn_upd_cnt)   := gt_lot_data_tbl(ln_cnt).trans_qty;   -- ����
      gt_attribute1_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute1;  -- OPM���b�g�}�X�^ �c�e�e���ڂP
      gt_attribute2_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute2;  -- OPM���b�g�}�X�^ �c�e�e���ڂQ
      gt_attribute3_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute3;  -- OPM���b�g�}�X�^ �c�e�e���ڂR
      gt_attribute4_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute4;  -- OPM���b�g�}�X�^ �c�e�e���ڂS
      gt_attribute5_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute5;  -- OPM���b�g�}�X�^ �c�e�e���ڂT
      gt_attribute6_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute6;  -- OPM���b�g�}�X�^ �c�e�e���ڂU
      gt_unit_price_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).unit_price;  -- �P��
      gt_attribute8_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute8;  -- OPM���b�g�}�X�^ �c�e�e���ڂW
      gt_attribute9_upd_tab(gn_upd_cnt)  := gt_lot_data_tbl(ln_cnt).attribute9;  -- OPM���b�g�}�X�^ �c�e�e���ڂX
      gt_attribute10_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute10; -- OPM���b�g�}�X�^ �c�e�e���ڂP�O
      gt_attribute11_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute11; -- OPM���b�g�}�X�^ �c�e�e���ڂP�P
      gt_attribute12_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute12; -- OPM���b�g�}�X�^ �c�e�e���ڂP�Q
      gt_attribute13_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute13; -- OPM���b�g�}�X�^ �c�e�e���ڂP�R
      gt_attribute14_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute14; -- OPM���b�g�}�X�^ �c�e�e���ڂP�S
      gt_attribute15_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute15; -- OPM���b�g�}�X�^ �c�e�e���ڂP�T
      gt_attribute16_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute16; -- OPM���b�g�}�X�^ �c�e�e���ڂP�U
      gt_attribute17_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute17; -- OPM���b�g�}�X�^ �c�e�e���ڂP�V
      gt_attribute18_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute18; -- OPM���b�g�}�X�^ �c�e�e���ڂP�W
      gt_attribute19_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute19; -- OPM���b�g�}�X�^ �c�e�e���ڂP�X
      gt_attribute20_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute20; -- OPM���b�g�}�X�^ �c�e�e���ڂQ�O
      gt_attribute21_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute21; -- OPM���b�g�}�X�^ �c�e�e���ڂQ�P
      gt_attribute22_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute22; -- OPM���b�g�}�X�^ �c�e�e���ڂQ�Q
      gt_attribute23_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute23; -- OPM���b�g�}�X�^ �c�e�e���ڂQ�R
      gt_attribute24_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute24; -- OPM���b�g�}�X�^ �c�e�e���ڂQ�S
      gt_attribute25_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute25; -- OPM���b�g�}�X�^ �c�e�e���ڂQ�T
      gt_attribute26_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute26; -- OPM���b�g�}�X�^ �c�e�e���ڂQ�U
      gt_attribute27_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute27; -- OPM���b�g�}�X�^ �c�e�e���ڂQ�V
      gt_attribute28_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute28; -- OPM���b�g�}�X�^ �c�e�e���ڂQ�W
      gt_attribute29_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute29; -- OPM���b�g�}�X�^ �c�e�e���ڂQ�X
      gt_attribute30_upd_tab(gn_upd_cnt) := gt_lot_data_tbl(ln_cnt).attribute30; -- OPM���b�g�}�X�^ �c�e�e���ڂR�O
--
    END LOOP upd_data_loop;
--
    IF ( gn_upd_cnt > 0 ) THEN
      -- �f�[�^�J�E���g�𐬌��f�[�^�J�E���g�ɃZ�b�g
      gn_normal_cnt := gn_upd_cnt;
    ELSE
      -- �����Ώۃ��R�[�h��0���̏ꍇ
      -- �G���[���b�Z�[�W�擾
      lv_errmsg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                    gv_xxcmn            -- ���W���[�������́FXXCMN �}�X�^�E�o������
                   ,gv_msg_xxcmn10036   -- ���b�Z�[�W�FAPP-XXCMN-10036 �f�[�^�擾�G���[
                   ),1,5000);
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_lot_cost;
--
  /**********************************************************************************
   * Procedure Name   : upd_table_api
   * Description      : OPM���b�g�}�X�^�X�V����(D-2)
   ***********************************************************************************/
  PROCEDURE upd_table_api(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_table_api'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    ln_user_id          NUMBER;            -- ���O�C�����Ă��郆�[�U�[
    ln_login_id         NUMBER;            -- �ŏI�X�V���O�C��
    ln_conc_request_id  NUMBER;            -- �v��ID
    ln_prog_appl_id     NUMBER;            -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
    ln_conc_program_id  NUMBER;            -- �R���J�����g�E�v���O����ID
--
    in_api_version      NUMBER DEFAULT 1.0;
    lv_return_status    VARCHAR2(30);
    ln_msg_count        NUMBER;
    lv_msg_data         VARCHAR2(2000);
    lr_lot_rec          ic_lots_mst%ROWTYPE;
    lv_api_name         VARCHAR2(200);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================
    -- �X�V����
    -- =====================================
    <<upd_lot_loop>>
    FOR ln_cnt IN 1..gt_item_id_upd_tab.COUNT LOOP
--
      lr_lot_rec.item_id     := gt_item_id_upd_tab(ln_cnt);     -- �i��ID
      lr_lot_rec.lot_id      := gt_lot_id_upd_tab(ln_cnt);      -- ���b�gID
      lr_lot_rec.lot_no      := gt_lot_num_upd_tab(ln_cnt);     -- ���b�gNo
      lr_lot_rec.attribute1  := gt_attribute1_upd_tab(ln_cnt);  -- �c�e�e���ڂP
      lr_lot_rec.attribute2  := gt_attribute2_upd_tab(ln_cnt);  -- �c�e�e���ڂQ
      lr_lot_rec.attribute3  := gt_attribute3_upd_tab(ln_cnt);  -- �c�e�e���ڂR
      lr_lot_rec.attribute4  := gt_attribute4_upd_tab(ln_cnt);  -- �c�e�e���ڂS
      lr_lot_rec.attribute5  := gt_attribute5_upd_tab(ln_cnt);  -- �c�e�e���ڂT
      lr_lot_rec.attribute6  := gt_attribute6_upd_tab(ln_cnt);  -- �c�e�e���ڂU
      lr_lot_rec.attribute7  := gt_unit_price_upd_tab(ln_cnt);  -- �P��
      lr_lot_rec.attribute8  := gt_attribute8_upd_tab(ln_cnt);  -- �c�e�e���ڂW
      lr_lot_rec.attribute9  := gt_attribute9_upd_tab(ln_cnt);  -- �c�e�e���ڂX
      lr_lot_rec.attribute10 := gt_attribute10_upd_tab(ln_cnt); -- �c�e�e���ڂP�O
      lr_lot_rec.attribute11 := gt_attribute11_upd_tab(ln_cnt); -- �c�e�e���ڂP�P
      lr_lot_rec.attribute12 := gt_attribute12_upd_tab(ln_cnt); -- �c�e�e���ڂP�Q
      lr_lot_rec.attribute13 := gt_attribute13_upd_tab(ln_cnt); -- �c�e�e���ڂP�R
      lr_lot_rec.attribute14 := gt_attribute14_upd_tab(ln_cnt); -- �c�e�e���ڂP�S
      lr_lot_rec.attribute15 := gt_attribute15_upd_tab(ln_cnt); -- �c�e�e���ڂP�T
      lr_lot_rec.attribute16 := gt_attribute16_upd_tab(ln_cnt); -- �c�e�e���ڂP�U
      lr_lot_rec.attribute17 := gt_attribute17_upd_tab(ln_cnt); -- �c�e�e���ڂP�V
      lr_lot_rec.attribute18 := gt_attribute18_upd_tab(ln_cnt); -- �c�e�e���ڂP�W
      lr_lot_rec.attribute19 := gt_attribute19_upd_tab(ln_cnt); -- �c�e�e���ڂP�X
      lr_lot_rec.attribute20 := gt_attribute20_upd_tab(ln_cnt); -- �c�e�e���ڂQ�O
      lr_lot_rec.attribute21 := gt_attribute21_upd_tab(ln_cnt); -- �c�e�e���ڂQ�P
      lr_lot_rec.attribute22 := gt_attribute22_upd_tab(ln_cnt); -- �c�e�e���ڂQ�Q
      lr_lot_rec.attribute23 := gt_attribute23_upd_tab(ln_cnt); -- �c�e�e���ڂQ�R
      lr_lot_rec.attribute24 := gt_attribute24_upd_tab(ln_cnt); -- �c�e�e���ڂQ�S
      lr_lot_rec.attribute25 := gt_attribute25_upd_tab(ln_cnt); -- �c�e�e���ڂQ�T
      lr_lot_rec.attribute26 := gt_attribute26_upd_tab(ln_cnt); -- �c�e�e���ڂQ�U
      lr_lot_rec.attribute27 := gt_attribute27_upd_tab(ln_cnt); -- �c�e�e���ڂQ�V
      lr_lot_rec.attribute28 := gt_attribute28_upd_tab(ln_cnt); -- �c�e�e���ڂQ�W
      lr_lot_rec.attribute29 := gt_attribute29_upd_tab(ln_cnt); -- �c�e�e���ڂQ�X
      lr_lot_rec.attribute30 := gt_attribute30_upd_tab(ln_cnt); -- �c�e�e���ڂR�O
      -- 2004/04/25 1.1
      lr_lot_rec.last_update_date := gd_date;
      lr_lot_rec.last_updated_by  := gn_user_id;
--
      -- OPM���b�g�}�X�^
      GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF (
          P_API_VERSION          => in_api_version
         ,X_RETURN_STATUS        => lv_return_status
         ,X_MSG_COUNT            => ln_msg_count
         ,X_MSG_DATA             => lv_msg_data
         ,P_LOT_REC              => lr_lot_rec
      );
--
      -- ���s
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        lv_api_name := 'GMI_LOTUPDATE_PUB.UPDATE_LOT_DFF';
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_msg_kbn, gv_msg_80a_016,
                                            gv_tkn_api_name, lv_api_name);
--
        FND_MSG_PUB.GET( P_MSG_INDEX     => 1, 
                         P_ENCODED       => FND_API.G_FALSE,
                         P_DATA          => lv_msg_data,
                         P_MSG_INDEX_OUT => ln_msg_count );
--
        lv_errbuf := lv_msg_data;
        RAISE global_api_expt;
      END IF;
--
    END LOOP upd_lot_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END upd_table_api;
--
  /**********************************************************************************
   * Procedure Name   : get_data_dump
   * Description      : �f�[�^�_���v�擾����
   ***********************************************************************************/
  PROCEDURE get_data_dump(
    ir_xxcmn_lot_cost     IN  xxcmn_lot_cost%ROWTYPE,  
                                                -- ���b�g�ʌ����i�A�h�I���j
    ov_dump               OUT NOCOPY VARCHAR2,  -- �f�[�^�_���v������
    ov_errbuf             OUT NOCOPY VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data_dump'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================
    -- �f�[�^�_���v�쐬
    -- ===============================
--
    ov_dump :=  TO_CHAR(ir_xxcmn_lot_cost.item_id)    -- �i��ID
                || gv_msg_comma ||
                ir_xxcmn_lot_cost.item_code           -- �i�ڃR�[�h
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_lot_cost.lot_id)     -- ���b�gID
                || gv_msg_comma ||
                ir_xxcmn_lot_cost.lot_num             -- ���b�gNO
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_lot_cost.trans_qty)  -- �������
                || gv_msg_comma ||
                TO_CHAR(ir_xxcmn_lot_cost.unit_ploce) -- �P��
                ;
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_data_dump;
--
  /**********************************************************************************
   * Procedure Name   : put_success_dump
   * Description      : �����f�[�^�_���v�o�͏���
   ***********************************************************************************/
  PROCEDURE put_success_dump(
    ov_errbuf   OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode  OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg   OUT NOCOPY VARCHAR2)  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_success_dump'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_msg  VARCHAR2(5000);  -- ���b�Z�[�W
    lv_dump VARCHAR2(5000);  -- �f�[�^�_���v
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
    upd_data_rec  xxcmn_lot_cost%ROWTYPE; -- ���b�g�ʌ����i�A�h�I���j�^���R�[�h
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    -- �����f�[�^�i���o���j
    lv_msg  := SUBSTRB(xxcmn_common_pkg.get_msg(
                 gv_xxcmn               -- ���W���[�������́FXXCMN ����
                ,gv_msg_xxcmn00005      -- ���b�Z�[�W�FAPP-XXCMN-00005 �����f�[�^�i���o���j
                ),1,5000);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_msg);
--
    << success_dump_set_loop >>
    FOR ln_rec_cnt IN 1..gt_item_id_upd_tab.COUNT LOOP
--
      -- =============================
      -- �_���v�p���R�[�h�ɃZ�b�g
      -- =============================
      upd_data_rec.item_id    := gt_item_id_upd_tab(ln_rec_cnt);     -- �i��ID
      upd_data_rec.item_code  := gt_item_code_upd_tab(ln_rec_cnt);   -- �i�ڃR�[�h
      upd_data_rec.lot_id     := gt_lot_id_upd_tab(ln_rec_cnt);      -- ���b�gID
      upd_data_rec.lot_num    := gt_lot_num_upd_tab(ln_rec_cnt);     -- ���b�gNo
      upd_data_rec.trans_qty  := gt_trans_qty_upd_tab(ln_rec_cnt);   -- ����
      upd_data_rec.unit_ploce := gt_unit_price_upd_tab(ln_rec_cnt);  -- �P��
--
      -- =============================
      -- �f�[�^�_���v�擾����
      -- =============================
      get_data_dump(
          ir_xxcmn_lot_cost => upd_data_rec
        , ov_dump           => lv_dump
        , ov_errbuf         => lv_errbuf
        , ov_retcode        => lv_retcode
        , ov_errmsg         => lv_errmsg
      );
      -- �f�[�^�_���v�擾�������G���[�̏ꍇ
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- =============================
      -- �����f�[�^���o��
      -- =============================
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_dump);
--
    END LOOP success_dump_set_loop;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END put_success_dump;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gd_date       := SYSDATE;
    gn_user_id    := FND_GLOBAL.USER_ID;
--
    -- �X�V�pPL/SQL�\������
    gt_item_id_upd_tab.DELETE;     -- �i��ID
    gt_item_code_upd_tab.DELETE;   -- �i�ڃR�[�h
    gt_lot_id_upd_tab.DELETE;      -- ���b�gID
    gt_lot_num_upd_tab.DELETE;     -- ���b�gNo
    gt_trans_qty_upd_tab.DELETE;   -- �������
    gt_attribute1_upd_tab.DELETE;  -- �c�e�e���ڂP
    gt_attribute2_upd_tab.DELETE;  -- �c�e�e���ڂQ
    gt_attribute3_upd_tab.DELETE;  -- �c�e�e���ڂR
    gt_attribute4_upd_tab.DELETE;  -- �c�e�e���ڂS
    gt_attribute5_upd_tab.DELETE;  -- �c�e�e���ڂT
    gt_attribute6_upd_tab.DELETE;  -- �c�e�e���ڂU
    gt_unit_price_upd_tab.DELETE;  -- �P��
    gt_attribute8_upd_tab.DELETE;  -- �c�e�e���ڂW
    gt_attribute9_upd_tab.DELETE;  -- �c�e�e���ڂX
    gt_attribute10_upd_tab.DELETE; -- �c�e�e���ڂP�O
    gt_attribute11_upd_tab.DELETE; -- �c�e�e���ڂP�P
    gt_attribute12_upd_tab.DELETE; -- �c�e�e���ڂP�Q
    gt_attribute13_upd_tab.DELETE; -- �c�e�e���ڂP�R
    gt_attribute14_upd_tab.DELETE; -- �c�e�e���ڂP�S
    gt_attribute15_upd_tab.DELETE; -- �c�e�e���ڂP�T
    gt_attribute16_upd_tab.DELETE; -- �c�e�e���ڂP�U
    gt_attribute17_upd_tab.DELETE; -- �c�e�e���ڂP�V
    gt_attribute18_upd_tab.DELETE; -- �c�e�e���ڂP�W
    gt_attribute19_upd_tab.DELETE; -- �c�e�e���ڂP�X
    gt_attribute20_upd_tab.DELETE; -- �c�e�e���ڂQ�O
    gt_attribute21_upd_tab.DELETE; -- �c�e�e���ڂQ�P
    gt_attribute22_upd_tab.DELETE; -- �c�e�e���ڂQ�Q
    gt_attribute23_upd_tab.DELETE; -- �c�e�e���ڂQ�R
    gt_attribute24_upd_tab.DELETE; -- �c�e�e���ڂQ�S
    gt_attribute25_upd_tab.DELETE; -- �c�e�e���ڂQ�T
    gt_attribute26_upd_tab.DELETE; -- �c�e�e���ڂQ�U
    gt_attribute27_upd_tab.DELETE; -- �c�e�e���ڂQ�V
    gt_attribute28_upd_tab.DELETE; -- �c�e�e���ڂQ�W
    gt_attribute29_upd_tab.DELETE; -- �c�e�e���ڂQ�X
    gt_attribute30_upd_tab.DELETE; -- �c�e�e���ڂR�O
--
    -- =======================================
    -- D-1.���b�g�ʌ����f�[�^���o����
    -- =======================================
    get_lot_cost(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- D-2.OPM���b�g�}�X�^�X�V����
    -- =======================================
    upd_table_api(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- ���b�g�ʌ����f�[�^�o�^�������G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- �����f�[�^�_���v�o�͏���
    -- =======================================
    put_success_dump(
       ov_errbuf  => lv_errbuf    -- �G���[�E���b�Z�[�W           --# �Œ� #
     , ov_retcode => lv_retcode   -- ���^�[���E�R�[�h             --# �Œ� #
     , ov_errmsg  => lv_errmsg    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    -- �����f�[�^�_���v�o�͏������G���[�̏ꍇ
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode       OUT NOCOPY VARCHAR2       --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �Œ�o�͗p�ϐ��Z�b�g
    -- ======================
    --���s���[�U���擾
    gv_exec_user := fnd_global.user_name;
    --���s�R���J�����g���擾
    SELECT fcp.concurrent_program_name
    INTO   gv_conc_name
    FROM   fnd_concurrent_programs fcp
    WHERE  fcp.application_id        = fnd_global.prog_appl_id
    AND    fcp.concurrent_program_id = fnd_global.conc_program_id
    AND    ROWNUM                    = 1;
--
    -- ======================
    -- �Œ�o��
    -- ======================
    --���s���[�U���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00001','USER',gv_exec_user);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���s�R���J�����g���o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00002','CONC',gv_conc_name);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�N�����ԏo��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118',
                                           'TIME', TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    --��؂蕶���o��
    gv_sep_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00003');
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,  -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF (lv_retcode = gv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        --��^���b�Z�[�W�E�Z�b�g
        lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10030');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
    END IF;
    -- ==================================
    -- ���^�[���E�R�[�h�̃Z�b�g�A�I������
    -- ==================================
    --��؂蕶����o��
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_sep_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00008','CNT',TO_CHAR(gn_target_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --���������o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00009','CNT',TO_CHAR(gn_normal_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�G���[�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00010','CNT',TO_CHAR(gn_error_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�L�b�v�����o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�o��
    SELECT flv.meaning
    INTO   gv_conc_status
    FROM   fnd_lookup_values flv
    WHERE  flv.language            = userenv('LANG')
    AND    flv.view_application_id = 0
    AND    flv.security_group_id   = fnd_global.lookup_security_group(flv.lookup_type, 
                                                                      flv.view_application_id)
    AND    flv.lookup_type         = 'CP_STATUS_CODE'
    AND    flv.lookup_code         = DECODE(lv_retcode,
                                            gv_status_normal,gv_sts_cd_normal,
                                            gv_status_warn,gv_sts_cd_warn,
                                            gv_sts_cd_error)
    AND    ROWNUM                  = 1;
--
    --�����X�e�[�^�X�o��
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00012','STATUS',gv_conc_status);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = gv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn790004c;
/
