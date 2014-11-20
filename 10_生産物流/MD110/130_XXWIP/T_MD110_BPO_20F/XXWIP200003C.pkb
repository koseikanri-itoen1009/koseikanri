CREATE OR REPLACE PACKAGE BODY xxwip200003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP200003C(body)
 * Description      : �o�������уA�b�v���[�h
 * MD.050           : ���Y�o�b�` T_MD050_BPO_202
 * MD.070           : �o�������уA�b�v���[�h T_MD070_BPO_20F
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_profile            �v���t�@�C���擾�v���V�[�W��
 *  get_if_data            ���уf�[�^�擾�v���V�[�W��(E-1)
 *  get_tbl_lock           ���b�N�擾�v���V�[�W��(E-2)
 *  proc_check             �`�F�b�N�����v���V�[�W��(E-3)
 *  proc_lot_execute       ���b�g�o�^�E�X�V�����v���V�[�W��(E-4)
 *  proc_make_qt           �i�����������v���V�[�W��(E-5)
 *  proc_update_material   �o�������я����v���V�[�W��(E-6)
 *  proc_update_price      �݌ɒP���X�V�����v���V�[�W��(E-7)
 *  proc_save_batch        ���Y�Z�[�u�����v���V�[�W��(E-8)
 *  term_proc              �C���^�t�F�[�X�e�[�u���폜�����v���V�[�W��(E-9)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/06    1.0   Oracle �R�� ��_ ����쐬
 *  2008/05/27    1.1   Oracle ��r ��� �����e�X�g�s��Ή�(�����֐����s���ɑq�ɃR�[�h�w��ǉ�)
 *  2008/06/12    1.2   Oracle ��r ��� ST�e�X�g�s��Ή�#81
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
  gv_msg_dot       CONSTANT VARCHAR2(3) := '.';
  gv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  check_sub_main_expt             EXCEPTION;     -- �T�u���C���ł̃G���[
  check_get_if_data_expt          EXCEPTION;     -- ���уf�[�^�擾�ł̃G���[
  check_get_tbl_lock_expt         EXCEPTION;     -- ���b�N�����ł̃G���[
  check_proc_check_expt           EXCEPTION;     -- �`�F�b�N�����̃G���[
  check_proc_lot_execute_expt     EXCEPTION;     -- ���b�g�o�^�E�X�V�����̃G���[
  check_proc_make_qt_expt         EXCEPTION;     -- �i�����������̃G���[
  check_proc_update_mat_expt      EXCEPTION;     -- �o�������я����̃G���[
  check_proc_update_price_expt    EXCEPTION;     -- �݌ɒP���X�V�����̃G���[
  check_proc_save_batch_expt      EXCEPTION;     -- ���Y�Z�[�u�����̃G���[
--
  lock_expt                       EXCEPTION;     -- ���b�N�擾�G���[
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxwip200003c'; -- �p�b�P�[�W��
  gv_item_class_code  CONSTANT VARCHAR2(1)   := '5';
  gv_test_code_mi     CONSTANT VARCHAR2(2)   := '10';
  gv_test_code_ok     CONSTANT VARCHAR2(2)   := '50';
  gv_data_ok          CONSTANT VARCHAR2(1)   := '0';
  gv_data_comp        CONSTANT VARCHAR2(1)   := '1';
  gv_test_code_off    CONSTANT VARCHAR2(1)   := '0';
  gv_test_code_on     CONSTANT VARCHAR2(1)   := '1';
  gv_division_prod    CONSTANT VARCHAR2(1)   := '1';
  gv_disposal_div_add CONSTANT VARCHAR2(1)   := '1';
  gv_disposal_div_upd CONSTANT VARCHAR2(1)   := '2';
--
  gv_prf_master_org_name    CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �e�}�X�^�ւ̔��f�����ɕK�v�ȃf�[�^���i�[���郌�R�[�h
  TYPE masters_rec IS RECORD(
    volume_actual_if_id   xxwip_volume_actual_if.volume_actual_if_id%TYPE,   -- �o��������IFID
    plant_code            xxwip_volume_actual_if.plant_code%TYPE,            -- �v�����g�R�[�h
    batch_no              xxwip_volume_actual_if.batch_no%TYPE,              -- ��zNo
    item_code             xxwip_volume_actual_if.item_code%TYPE,             -- �i�ڃR�[�h
    volume_actual_qty     xxwip_volume_actual_if.volume_actual_qty%TYPE,     -- �o�������ѐ�
    rcv_date              xxwip_volume_actual_if.rcv_date%TYPE,              -- ������ѓ�
    actual_date           xxwip_volume_actual_if.actual_date%TYPE,           -- ���Y��
    maker_date            xxwip_volume_actual_if.maker_date%TYPE,            -- ������
    expiration_date       xxwip_volume_actual_if.expiration_date%TYPE,       -- �ܖ�������
--
    -- ��������
    batch_id              gme_batch_header.batch_id%TYPE,                    -- �o�b�`ID
    routing_no            gmd_routings_b.routing_no%TYPE,                    -- �H���ԍ�
    routing_id            gmd_routings_b.routing_id%TYPE,                    -- �H��ID
    attribute19           gmd_routings_b.attribute19%TYPE,                   -- �ŗL�ԍ�
    attribute13           gmd_routings_b.attribute13%TYPE,                   -- ���Y�`�[�敪
    attribute9            gmd_routings_b.attribute9%TYPE,                    -- �[�i�ꏊ
    attribute20           gmd_routings_b.attribute20%TYPE,                   -- ��ƕ���
-- 2008/05/27 D.Nihei INS START
    attribute21           gmd_routings_b.attribute21%TYPE,                   -- �[�i�q��
-- 2008/05/27 D.Nihei INS END
    inventory_location_id xxcmn_item_locations_v.inventory_location_id%TYPE, -- �q��ID
    test_code             xxcmn_item_mst_v.test_code%TYPE,                   -- �����L���敪
    item_um               xxcmn_item_mst_v.item_um%TYPE,                     -- �P��
    num_of_cases          xxcmn_item_mst_v.num_of_cases%TYPE,                -- �P�[�X����
    frequent_qty          xxcmn_item_mst_v.frequent_qty%TYPE,                -- ��\����
    item_class_code       xxcmn_item_categories3_v.item_class_code%TYPE,     -- �i�ڋ敪
    material_detail_id    gme_material_details.material_detail_id%TYPE,      -- ���Y�����ڍ�ID
    item_id               gme_material_details.item_id%TYPE,                 -- �i��ID
    lot_id                ic_tran_pnd.lot_id%TYPE,                           -- ���b�gID
    lot_no                ic_lots_mst.lot_no%TYPE,                           -- ���b�gNO
    attribute22           ic_lots_mst.attribute22%TYPE,                      -- �i�������˗�NO
    batch_status          gme_batch_header.batch_status%TYPE,                -- �o�b�`�X�e�[�^�X
--
    in_data               VARCHAR2(5000),                                    -- ���̓f�[�^
--
    error_flg             BOOLEAN                                            -- ��������
--
  );
--
  -- �e�}�X�^�֔��f����f�[�^���i�[���錋���z��
  TYPE masters_tbl IS TABLE OF masters_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gv_prf_master_org_id      VARCHAR2(100);
  gt_mast_tb                masters_tbl; -- �e�}�X�^�֓o�^����f�[�^
  gv_batch_no               xxwip_volume_actual_if.batch_no%TYPE;
--
  gd_sysdate               DATE;
  gn_user_id               NUMBER(15);
  gn_login_id              NUMBER(15);
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���J�[�\��
  -- ===============================
    -- ���Y�o�b�`�w�b�_
    CURSOR gc_gbh_cur
    IS
      SELECT gbh.batch_id
      FROM   gme_batch_header gbh
      WHERE  gbh.batch_no = gv_batch_no
      AND    ROWNUM = 1
      FOR UPDATE OF gbh.batch_id NOWAIT;
--
    -- ���Y�����ڍ�
    CURSOR gc_gmd_cur
    IS
      SELECT gmd.batch_id
      FROM   gme_material_details gmd
      WHERE  EXISTS (
        SELECT gbh.batch_id
        FROM   gme_batch_header gbh
        WHERE  gbh.batch_no = gv_batch_no
        AND    gmd.batch_id = gbh.batch_id
        AND    ROWNUM = 1)
      FOR UPDATE OF gmd.batch_id NOWAIT;
--
    -- OPM�ۗ��݌Ƀg�����U�N�V����
    CURSOR gc_itp_cur
    IS
      SELECT itp.trans_id
      FROM   ic_tran_pnd itp
      WHERE  EXISTS (
        SELECT gbh.batch_id
        FROM   gme_batch_header gbh
        WHERE  gbh.batch_no = gv_batch_no
        AND    itp.doc_id   = gbh.batch_id
        AND    ROWNUM = 1)
      FOR UPDATE OF itp.trans_id NOWAIT;
--
  /***********************************************************************************
   * Procedure Name   : get_profile
   * Description      : �v���t�@�C�����}�X�^�g�DID���擾���܂��B
   ***********************************************************************************/
  PROCEDURE get_profile(
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
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
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    --�}�X�^�g�DID�擾
    gv_prf_master_org_id := FND_PROFILE.VALUE(gv_prf_master_org_name);
--
    -- �v���t�@�C�����擾�ł��Ȃ��ꍇ�̓G���[
    IF (gv_prf_master_org_id IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10067',
                                            'NG_PROFILE',
                                            '�}�X�^�g�DID');
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_profile;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ���уf�[�^�擾(E-1)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- �v���O������
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
    lb_retcd  BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR actual_if_cur
    IS
      SELECT volume_actual_if_id
            ,plant_code
            ,batch_no
            ,item_code
            ,volume_actual_qty
            ,rcv_date
            ,actual_date
            ,maker_date
            ,expiration_date
            ,volume_actual_if_id||gv_msg_pnt||
             plant_code||gv_msg_pnt||
             batch_no||gv_msg_pnt||
             item_code||gv_msg_pnt||
             volume_actual_qty||gv_msg_pnt||
             rcv_date||gv_msg_pnt||
             actual_date||gv_msg_pnt||
             maker_date||gv_msg_pnt||
             expiration_date as in_data
      FROM  xxwip_volume_actual_if
      ORDER BY plant_code,batch_no;
--
    -- *** ���[�J���E���R�[�h ***
    lr_actual_if_rec actual_if_cur%ROWTYPE;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lb_retcd := TRUE;
--
    -- �e�[�u�����b�N����(�o�������уC���^�t�F�[�X)
    lb_retcd := xxcmn_common_pkg.get_tbl_lock('XXWIP', 'xxwip_volume_actual_if');
--
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10004',
                                            'TABLE',
                                            '�o�������уC���^�t�F�[�X');
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    OPEN actual_if_cur;
--
    <<actual_if_loop>>
    LOOP
      FETCH actual_if_cur INTO lr_actual_if_rec;
      EXIT WHEN actual_if_cur%NOTFOUND;
--
      gt_mast_tb(gn_target_cnt).volume_actual_if_id := lr_actual_if_rec.volume_actual_if_id;
      gt_mast_tb(gn_target_cnt).plant_code          := lr_actual_if_rec.plant_code;
      gt_mast_tb(gn_target_cnt).batch_no            := lr_actual_if_rec.batch_no;
      gt_mast_tb(gn_target_cnt).item_code           := lr_actual_if_rec.item_code;
      gt_mast_tb(gn_target_cnt).volume_actual_qty   := lr_actual_if_rec.volume_actual_qty;
      gt_mast_tb(gn_target_cnt).rcv_date            := lr_actual_if_rec.rcv_date;
      gt_mast_tb(gn_target_cnt).actual_date         := lr_actual_if_rec.actual_date;
      gt_mast_tb(gn_target_cnt).maker_date          := lr_actual_if_rec.maker_date;
      gt_mast_tb(gn_target_cnt).expiration_date     := lr_actual_if_rec.expiration_date;
      gt_mast_tb(gn_target_cnt).in_data             := lr_actual_if_rec.in_data;
--
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP actual_if_loop;
--
    CLOSE actual_if_cur;
--
    -- �f�[�^�Ȃ�
    IF (gn_target_cnt = 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP','APP-XXWIP-10040');
      RAISE check_get_if_data_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_get_if_data_expt THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (actual_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE actual_if_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (actual_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE actual_if_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (actual_if_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE actual_if_cur;
      END IF;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END get_if_data;
--
  /***********************************************************************************
   * Procedure Name   : get_tbl_lock
   * Description      : �C���^�t�F�[�X�̃e�[�u�����b�N���s���܂��B(E-2)
   ***********************************************************************************/
  PROCEDURE get_tbl_lock(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tbl_lock'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd    BOOLEAN;
--
    ln_batch_id            gme_batch_header.batch_id%TYPE;
    ln_trans_id            ic_tran_pnd.trans_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    gv_batch_no := ir_masters_rec.batch_no;
--
    -- ���Y�o�b�`�w�b�_
    BEGIN
      OPEN gc_gmd_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10004',
                                              'TABLE',
                                              '���Y�����ڍ�');
        lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
        RAISE check_get_tbl_lock_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- ���Y�����ڍ�
    BEGIN
      OPEN gc_gbh_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10004',
                                              'TABLE',
                                              '���Y�o�b�`�w�b�_');
        lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
        RAISE check_get_tbl_lock_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    -- OPM�ۗ��݌Ƀg�����U�N�V����
    BEGIN
      OPEN gc_itp_cur;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10004',
                                              'TABLE',
                                              'OPM�ۗ��݌Ƀg�����U�N�V����');
        lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
        RAISE check_get_tbl_lock_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_get_tbl_lock_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END get_tbl_lock;
--
  /***********************************************************************************
   * Procedure Name   : proc_check
   * Description      : �`�F�b�N�������s���܂��B(E-3)
   ***********************************************************************************/
  PROCEDURE proc_check(
    ir_masters_rec  IN OUT NOCOPY masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_check'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd  BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    BEGIN
      SELECT gbh.batch_id                                               -- �o�b�`ID
            ,grb.routing_no                                             -- �H���ԍ�
            ,grb.routing_id                                             -- �H��ID
            ,grb.attribute19                                            -- �ŗL�ԍ�
            ,grb.attribute13                                            -- ���Y�`�[�敪
            ,grb.attribute9                                             -- �[�i�ꏊ
            ,grb.attribute20                                            -- ��ƕ���
-- 2008/05/27 D.Nihei INS START
            ,grb.attribute21                                            -- �[�i�q��
-- 2008/05/27 D.Nihei INS END
            ,xilv.inventory_location_id                                 -- �q��ID
            ,ximv.test_code                                             -- �����L���敪
            ,ximv.item_um                                               -- �P��
            ,ximv.num_of_cases                                          -- �P�[�X����
            ,ximv.frequent_qty                                          -- ��\����
            ,xicv.item_class_code                                       -- �i�ڋ敪
            ,gmd.material_detail_id                                     -- ���Y�����ڍ�ID
            ,gmd.item_id                                                -- �i��ID
            ,itp.lot_id                                                 -- ���b�gID
            ,ilm.lot_no                                                 -- ���b�gNO
            ,ilm.attribute22                                            -- �i�������˗�NO
            ,gbh.batch_status                                           -- �o�b�`�X�e�[�^�X
      INTO   ir_masters_rec.batch_id
            ,ir_masters_rec.routing_no
            ,ir_masters_rec.routing_id
            ,ir_masters_rec.attribute19
            ,ir_masters_rec.attribute13
            ,ir_masters_rec.attribute9
            ,ir_masters_rec.attribute20
-- 2008/05/27 D.Nihei INS START
            ,ir_masters_rec.attribute21
-- 2008/05/27 D.Nihei INS END
            ,ir_masters_rec.inventory_location_id
            ,ir_masters_rec.test_code
            ,ir_masters_rec.item_um
            ,ir_masters_rec.num_of_cases
            ,ir_masters_rec.frequent_qty
            ,ir_masters_rec.item_class_code
            ,ir_masters_rec.material_detail_id
            ,ir_masters_rec.item_id
            ,ir_masters_rec.lot_id
            ,ir_masters_rec.lot_no
            ,ir_masters_rec.attribute22
            ,ir_masters_rec.batch_status
      FROM   gme_batch_header gbh                               -- ���Y�o�b�`�w�b�_
            ,gme_material_details gmd                           -- ���Y�����ڍ�
            ,gmd_routings_b grb                                 -- �H���}�X�^
            ,ic_tran_pnd itp                                    -- OPM�ۗ��݌Ƀg�����U�N�V����
            ,ic_lots_mst ilm                                    -- OPM���b�g�}�X�^
            ,xxcmn_item_locations_v xilv                        -- OPM�ۊǏꏊ���VIEW
            ,xxcmn_item_mst2_v ximv                             -- OPM�i�ڏ��VIEW2
            ,xxcmn_item_categories3_v xicv                      -- OPM�i�ڃJ�e�S���������VIEW3
      WHERE gbh.batch_id      = gmd.batch_id
      AND   gbh.routing_id    = grb.routing_id
      AND   xilv.segment1     = grb.attribute9
      AND   ximv.item_id      = gmd.item_id
      AND   ximv.item_id      = xicv.item_id
      AND   itp.line_type     = gmd.line_type
      AND   itp.doc_id        = gbh.batch_id
      AND   itp.line_id       = gmd.material_detail_id
      AND   itp.lot_id        = ilm.lot_id
      AND   gmd.item_id       = ilm.item_id
      AND   itp.lot_id        = 0
      AND   gmd.line_type     = 1
      AND   itp.delete_mark   = gv_data_ok
      AND   itp.completed_ind = gv_data_ok
      AND   ximv.item_no      = ir_masters_rec.item_code                -- �i�ڃR�[�h
      AND   gbh.plant_code    = ir_masters_rec.plant_code               -- �v�����g�R�[�h
      AND   gbh.batch_no      = ir_masters_rec.batch_no                 -- ��zNo
      AND   ximv.start_date_active <= ir_masters_rec.actual_date        -- ���Y��
      AND   ximv.end_date_active   >= ir_masters_rec.actual_date        -- ���Y��
      AND   ROWNUM            = 1;
--
    EXCEPTION
--
      WHEN NO_DATA_FOUND THEN
--
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10042',
                                              'TABLE_NAME',
                                              '���Y�o�b�`�w�b�_�e�[�u��',
                                              'DATA',
                                              ir_masters_rec.in_data);
--
        lv_errbuf := lv_errmsg;
        RAISE check_proc_check_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    -- �o�������ѐ����O�ȉ�
    IF (ir_masters_rec.volume_actual_qty <= 0) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10043',
                                            'ITEM',
                                            '�o�������ѐ�',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_check_expt;
    END IF;
--
    -- �i�ڋ敪�����i�ȊO
    IF (ir_masters_rec.item_class_code <> gv_item_class_code) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10071');
      RAISE check_proc_check_expt;
    END IF;
--
    -- �o�b�`�X�e�[�^�X���ۗ��ȊO
    IF (ir_masters_rec.batch_status <> '1') THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10072');
      RAISE check_proc_check_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_check_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_check;
--
  /***********************************************************************************
   * Procedure Name   : proc_lot_execute
   * Description      : ���b�g�o�^�E�X�V�������s���܂��B(E-4)
   ***********************************************************************************/
  PROCEDURE proc_lot_execute(
    ir_masters_rec  IN OUT NOCOPY  masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_lot_execute'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_in_lot_mst       ic_lots_mst%ROWTYPE;                 -- OPM���b�g�}�X�^
    lv_item_no          ic_item_mst_b.item_no%TYPE;          -- �i�ڃR�[�h
    ln_line_type        gme_material_details.line_type%TYPE; -- ���C���^�C�v
    lv_item_class_code  mtl_categories_b.segment1%TYPE;      -- �i�ڋ敪
    lv_lot_no_prod      ic_lots_mst.lot_no%TYPE;             -- �����i�̃��b�gNo
    lr_out_lot_mst      ic_lots_mst%ROWTYPE;                 -- OPM���b�g�}�X�^
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lv_item_no                := ir_masters_rec.item_code;
    lv_item_class_code        := ir_masters_rec.item_class_code;
    ln_line_type              := 1;
    lr_in_lot_mst.item_id     := ir_masters_rec.item_id;
    lr_in_lot_mst.lot_id      := ir_masters_rec.lot_id;
    lr_in_lot_mst.attribute1  := TO_CHAR(ir_masters_rec.maker_date,'YYYY/MM/DD');
    lr_in_lot_mst.attribute2  := ir_masters_rec.attribute19;
    lr_in_lot_mst.attribute3  := TO_CHAR(ir_masters_rec.expiration_date,'YYYY/MM/DD');
    lr_in_lot_mst.attribute16 := ir_masters_rec.attribute13;
    lr_in_lot_mst.attribute17 := ir_masters_rec.routing_no;
    lr_in_lot_mst.attribute6  := TO_CHAR(ir_masters_rec.num_of_cases);
--
    -- �����L���敪����
    IF (ir_masters_rec.test_code = gv_test_code_off) THEN
      -- ���b�g�X�e�[�^�X�Ɂf�P�O�f
      lr_in_lot_mst.attribute23 := gv_test_code_mi;
--
    -- �����L���敪���L
    ELSIF (ir_masters_rec.test_code = gv_test_code_on) THEN
      -- ���b�g�X�e�[�^�X�Ɂf�T�O�f
      lr_in_lot_mst.attribute23 := gv_test_code_ok;
    END IF;
--
    -- ���b�g�ǉ��E�X�V�֐�
    xxwip_common_pkg.lot_execute(
       ir_lot_mst         => lr_in_lot_mst
      ,it_item_no         => lv_item_no
      ,it_line_type       => ln_line_type
      ,it_item_class_code => lv_item_class_code
      ,it_lot_no_prod     => lv_lot_no_prod
      ,or_lot_mst         => lr_out_lot_mst
      ,ov_errbuf          => lv_errbuf
      ,ov_retcode         => lv_retcode
      ,ov_errmsg          => lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10050',
                                            'API_NAME',
                                            'XXWIP���b�g�ǉ��E�X�V�֐�',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_lot_execute_expt;
    END IF;
--
    ir_masters_rec.lot_id := lr_out_lot_mst.lot_id;
    ir_masters_rec.attribute22 := lr_out_lot_mst.attribute22;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_lot_execute_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_lot_execute;
--
  /***********************************************************************************
   * Procedure Name   : proc_make_qt
   * Description      : �i�������������s���܂��B(E-5)
   ***********************************************************************************/
  PROCEDURE proc_make_qt(
    ir_masters_rec  IN OUT NOCOPY  masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_make_qt'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_division       xxwip_qt_inspection.division%TYPE;             -- IN  1.�敪
    lv_disposal_div   VARCHAR2(1);                                   -- IN  2.�����敪
    ln_lot_id         xxwip_qt_inspection.lot_id%TYPE;               -- IN  3.���b�gID
    ln_item_id        xxwip_qt_inspection.item_id%TYPE;              -- IN  4.�i��ID
    lv_qt_object      VARCHAR2(1);                                   -- IN  5.�Ώې�
    ln_batch_id       xxwip_qt_inspection.batch_po_id%TYPE;          -- IN  6.���Y�o�b�`ID
    ln_batch_po_id    xxwip_qt_inspection.batch_po_id%TYPE;          -- IN  7.���הԍ�
    ln_qty            xxwip_qt_inspection.qty%TYPE;                  -- IN  8.����
    ld_prod_dely_date xxwip_qt_inspection.prod_dely_date%TYPE;       -- IN  9.�[����
    lv_vendor_line    xxwip_qt_inspection.vendor_line%TYPE;          -- IN 10.�d����R�[�h
    ln_in_req_no      xxwip_qt_inspection.qt_inspect_req_no%TYPE;    -- IN 11.�����˗�No
    ln_out_req_no     xxwip_qt_inspection.qt_inspect_req_no%TYPE;    -- OUT 1.�����˗�No
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �����L���敪���L�������˗�NO��NULL
    IF ((ir_masters_rec.test_code = gv_test_code_on)
    AND (ir_masters_rec.attribute22 IS NULL)) THEN
--
      lv_division     := gv_division_prod;                    -- �敪�F���Y
      lv_disposal_div := gv_disposal_div_add;                 -- �����敪�F�ǉ�
      ln_batch_id     := ir_masters_rec.batch_id;             -- ���Y�o�b�`ID
      ln_lot_id       := ir_masters_rec.lot_id;               -- ���b�gID
      ln_item_id      := ir_masters_rec.item_id;              -- �i��ID
--
      -- �i�������˗����쐬
      xxwip_common_pkg.make_qt_inspection(
         it_division          => lv_division
        ,iv_disposal_div      => lv_disposal_div
        ,it_lot_id            => ln_lot_id
        ,it_item_id           => ln_item_id
        ,iv_qt_object         => lv_qt_object
        ,it_batch_id          => ln_batch_id
        ,it_batch_po_id       => ln_batch_po_id
        ,it_qty               => ln_qty
        ,it_prod_dely_date    => ld_prod_dely_date
        ,it_vendor_line       => lv_vendor_line
        ,it_qt_inspect_req_no => ln_in_req_no
        ,ot_qt_inspect_req_no => ln_out_req_no
        ,ov_errbuf            => lv_errbuf
        ,ov_retcode           => lv_retcode
        ,ov_errmsg            => lv_errmsg
      );
--
      IF (lv_retcode = gv_status_error) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10050',
                                              'API_NAME',
                                              '�i�������˗����쐬',
                                              'DATA',
                                              ir_masters_rec.in_data);
        RAISE check_proc_make_qt_expt;
      END IF;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_make_qt_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_make_qt;
--
  /***********************************************************************************
   * Procedure Name   : proc_update_material
   * Description      : �o�������я������s���܂��B(E-6)
   ***********************************************************************************/
  PROCEDURE proc_update_material(
    ir_masters_rec  IN OUT NOCOPY  masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_update_material'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_message_count         NUMBER;                             -- ���b�Z�[�W�J�E���g
    lv_message_list          VARCHAR2(200);                      -- ���b�Z�[�W���X�g
    lv_return_status         VARCHAR2(100);                      -- ���^�[���X�e�[�^�X
    lr_tran_row_in           gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_out          gme_inventory_txns_gtmp%ROWTYPE;
    lr_tran_row_def          gme_inventory_txns_gtmp%ROWTYPE;
    lr_material_detail_out   gme_material_details%ROWTYPE;
    lr_gme_batch_header      gme_batch_header%ROWTYPE;
    lr_gme_batch_header_temp gme_batch_header%ROWTYPE;
    lr_unallocated_materials GME_API_PUB.UNALLOCATED_MATERIALS_TAB;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �X�e�[�^�X�X�V�֐������s
    xxwip_common_pkg.update_duty_status(
        in_batch_id     => ir_masters_rec.batch_id
        ,iv_duty_status => '7'
        ,ov_errbuf      => lv_errbuf
        ,ov_retcode     => lv_retcode
        ,ov_errmsg      => lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10050',
                                            'API_NAME',
                                            '�X�e�[�^�X�X�V�֐�',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_update_mat_expt;
    END IF;
--
    BEGIN
      -- ���Y�����ڍ�(���ڍX�V)
      UPDATE gme_material_details gmd
      SET    gmd.batch_id          = ir_masters_rec.batch_id
            ,gmd.attribute6        = TO_CHAR(ir_masters_rec.num_of_cases)
            ,gmd.attribute10       = TO_CHAR(ir_masters_rec.expiration_date,'YYYY/MM/DD')
            ,gmd.attribute11       = TO_CHAR(ir_masters_rec.actual_date,'YYYY/MM/DD')
            ,gmd.attribute17       = TO_CHAR(ir_masters_rec.maker_date,'YYYY/MM/DD')
            ,gmd.last_update_login = gn_login_id
            ,gmd.last_update_date  = gd_sysdate
            ,gmd.last_updated_by   = gn_user_id
      WHERE  gmd.material_detail_id = ir_masters_rec.material_detail_id;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                              'APP-XXWIP-10050',
                                              'API_NAME',
                                              '�������׍X�V�֐�',
                                              'DATA',
                                              ir_masters_rec.in_data);
        RAISE check_proc_update_mat_expt;
    END;
--
    lr_tran_row_in.doc_id             := ir_masters_rec.batch_id;
    lr_tran_row_in.lot_id             := ir_masters_rec.lot_id;
    lr_tran_row_in.trans_qty          := ir_masters_rec.volume_actual_qty;
    lr_tran_row_in.trans_date         := ir_masters_rec.actual_date;
    lr_tran_row_in.location           := ir_masters_rec.attribute9;
    lr_tran_row_in.material_detail_id := ir_masters_rec.material_detail_id;
    lr_tran_row_in.completed_ind      := gv_data_comp;
-- 2008/05/27 D.Nihei INS START
    lr_tran_row_in.whse_code          := ir_masters_rec.attribute21; -- �[�i�q��
-- 2008/05/27 D.Nihei INS END
--
    -- ���׊����ǉ��֐������s
    GME_API_PUB.INSERT_LINE_ALLOCATION(
       P_API_VERSION        => GME_API_PUB.API_VERSION
      ,P_VALIDATION_LEVEL   => GME_API_PUB.MAX_ERRORS
      ,P_INIT_MSG_LIST      => FALSE
      ,P_COMMIT             => FALSE
      ,P_TRAN_ROW           => lr_tran_row_in
      ,P_LOT_NO             => ir_masters_rec.lot_no
      ,P_SUBLOT_NO          => NULL
      ,P_CREATE_LOT         => FALSE
      ,P_IGNORE_SHORTAGE    => FALSE
      ,P_SCALE_PHANTOM      => FALSE
      ,X_MATERIAL_DETAIL    => lr_material_detail_out
      ,X_TRAN_ROW           => lr_tran_row_out
      ,X_DEF_TRAN_ROW       => lr_tran_row_def
      ,X_MESSAGE_COUNT      => ln_message_count
      ,X_MESSAGE_LIST       => lv_message_list
      ,X_RETURN_STATUS      => lv_return_status
    );
--
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10050',
                                            'API_NAME',
                                            '���׊����ǉ��֐�',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_update_mat_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_update_mat_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_update_material;
--
  /***********************************************************************************
   * Procedure Name   : proc_update_price
   * Description      : �݌ɒP���X�V�������s���܂��B(E-7)
   ***********************************************************************************/
  PROCEDURE proc_update_price(
    ir_masters_rec  IN OUT NOCOPY  masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_update_price'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    ln_batch_id  gme_batch_header.batch_id%TYPE;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    ln_batch_id := ir_masters_rec.batch_id;
--
    -- �݌ɒP���X�V�֐�
    xxwip_common_pkg.update_inv_price(
       it_batch_id  => ln_batch_id
      ,ov_errbuf    => lv_errbuf
      ,ov_retcode   => lv_retcode
      ,ov_errmsg    => lv_errmsg
    );
--
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10050',
                                            'API_NAME',
                                            'XXWIP�݌ɒP���X�V�֐�',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_update_price_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_update_price_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_update_price;
--
  /***********************************************************************************
   * Procedure Name   : proc_save_batch
   * Description      : ���Y�Z�[�u�������s���܂��B(E-8)
   ***********************************************************************************/
  PROCEDURE proc_save_batch(
    ir_masters_rec  IN OUT NOCOPY  masters_rec,
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_save_batch'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lr_batch_header  gme_batch_header%ROWTYPE;
    lv_return_status VARCHAR2(30);
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    lr_batch_header.batch_id := ir_masters_rec.batch_id;
--
    -- ���Y�o�b�`�Z�[�u
    GME_API_PUB.SAVE_BATCH (
      P_BATCH_HEADER    => lr_batch_header
     ,X_RETURN_STATUS   => lv_return_status
     ,P_COMMIT          => FALSE
    );
--
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXWIP',
                                            'APP-XXWIP-10050',
                                            'API_NAME',
                                            '���Y�o�b�`�Z�[�u API',
                                            'DATA',
                                            ir_masters_rec.in_data);
      RAISE check_proc_save_batch_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
    WHEN check_proc_save_batch_expt THEN
      ir_masters_rec.error_flg := FALSE;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_errmsg);
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END proc_save_batch;
--
  /***********************************************************************************
   * Procedure Name   : term_proc
   * Description      : �C���^�t�F�[�X�e�[�u���폜�������s���܂��B(E-9)
   ***********************************************************************************/
  PROCEDURE term_proc(
    ov_errbuf        OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'term_proc'; -- �v���O������
--
--##############################  �Œ胍�[�J���ϐ��錾�� START   ##################################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--#####################################  �Œ蕔 END   #############################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lb_retcd   BOOLEAN;
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
  BEGIN
--
--################################  �Œ�X�e�[�^�X�������� START   ################################
--
    ov_retcode := gv_status_normal;
--
 --#####################################  �Œ蕔 END   #############################################--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--
    -- �f�[�^�폜(�o�������уC���^�t�F�[�X)
    lb_retcd := xxcmn_common_pkg.del_all_data('XXWIP','xxwip_volume_actual_if');
--
    -- ���s
    IF (NOT lb_retcd) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg('XXCMN', 
                                            'APP-XXCMN-10022',
                                            'TABLE', 
                                            '�o�������уC���^�t�F�[�X');
--
      lv_errbuf := lv_errmsg ||gv_msg_part|| SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o��(�G���[�ȊO)������K�v������ꍇ�͏������L�q
    --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   #######################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   #############################################
--
  END term_proc;
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
    ln_cnt        NUMBER;
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
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
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    ln_cnt        := 0;
--
    gn_user_id     := FND_GLOBAL.USER_ID;
    gd_sysdate     := SYSDATE;
    gn_login_id    := FND_GLOBAL.LOGIN_ID;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- �v���t�@�C���̎擾
    get_profile(lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    -- ===============================
    -- ���уf�[�^�擾(E-1)
    -- ===============================
    get_if_data(lv_errbuf,
                lv_retcode,
                lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
--
    <<chk_price_loop>>
    FOR i IN 0..gn_target_cnt-1 LOOP
--
      gt_mast_tb(i).error_flg := TRUE;
--
      -- ===============================
      -- �e�[�u�����b�N�擾(E-2)
      -- ===============================
      get_tbl_lock(gt_mast_tb(i),
                  lv_errbuf,
                  lv_retcode,
                  lv_errmsg);
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE check_sub_main_expt;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- �`�F�b�N����(E-3)
        -- ===============================
        proc_check(gt_mast_tb(i),
                   lv_errbuf,
                   lv_retcode,
                   lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- ���b�g�o�^�E�X�V����(E-4)
        -- ===============================
        proc_lot_execute(gt_mast_tb(i),
                         lv_errbuf,
                         lv_retcode,
                         lv_errmsg);
  --
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- �o�������я���(E-6)
        -- ===============================
        proc_update_material(gt_mast_tb(i),
                             lv_errbuf,
                             lv_retcode,
                             lv_errmsg);
  --
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- ���Y�Z�[�u����(E-8)
        -- ===============================
        proc_save_batch(gt_mast_tb(i),
                        lv_errbuf,
                        lv_retcode,
                        lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- �݌ɒP���X�V����(E-7)
        -- ===============================
        proc_update_price(gt_mast_tb(i),
                          lv_errbuf,
                          lv_retcode,
                          lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      IF (gt_mast_tb(i).error_flg) THEN
        -- ===============================
        -- �i����������(E-5)
        -- ===============================
        proc_make_qt(gt_mast_tb(i),
                     lv_errbuf,
                     lv_retcode,
                     lv_errmsg);
--
        IF (lv_retcode = gv_status_error) THEN
          RAISE check_sub_main_expt;
        END IF;
      END IF;
--
      -- �J�[�\�����J���Ă����
      IF (gc_gmd_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_gmd_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_gbh_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_gbh_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_itp_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_itp_cur;
      END IF;
--
      -- ��������
      IF (gt_mast_tb(i).error_flg) THEN
        COMMIT;
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        ROLLBACK;
        gn_error_cnt := gn_error_cnt + 1;
      END IF;
--
    END LOOP chk_price_loop;
--
    -- ===============================
    -- �C���^�t�F�[�X�e�[�u���폜(E-9)
    -- ===============================
    term_proc(lv_errbuf,
              lv_retcode,
              lv_errmsg);
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE check_sub_main_expt;
    END IF;
-- 2008/06/12 D.Nihei ADD START
    -- ===============================
    -- ���^�[���R�[�h����
    -- ===============================
    -- �G���[������1���ł����݂���ꍇ�͌x���ɂ���
    IF (gn_error_cnt > 0) THEN
      ov_retcode := gv_status_warn;
    END IF;
-- 2008/06/12 D.Nihei ADD END
--
  EXCEPTION
    -- *** �C�ӂŗ�O�������L�q���� ****
    WHEN check_sub_main_expt THEN
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
      -- �J�[�\�����J���Ă����
      IF (gc_gmd_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_gmd_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_gbh_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_gbh_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_itp_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_itp_cur;
      END IF;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (gc_gmd_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_gmd_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_gbh_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_gbh_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_itp_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_itp_cur;
      END IF;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (gc_gmd_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_gmd_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_gbh_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_gbh_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_itp_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_itp_cur;
      END IF;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
      -- �J�[�\�����J���Ă����
      IF (gc_gmd_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_gmd_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_gbh_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_gbh_cur;
      END IF;
      -- �J�[�\�����J���Ă����
      IF (gc_itp_cur%ISOPEN) THEN
        -- �J�[�\���̃N���[�Y
        CLOSE gc_itp_cur;
      END IF;
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
--
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
    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-10118','TIME',
                                           TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'));
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
    submain(lv_errbuf,   -- �G���[�E���b�Z�[�W           --# �Œ� #
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
--    gv_out_msg := xxcmn_common_pkg.get_msg('XXCMN','APP-XXCMN-00011','CNT',TO_CHAR(gn_warn_cnt));
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gv_out_msg);
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
                                            gv_status_normal, gv_sts_cd_normal,
                                            gv_status_warn,   gv_sts_cd_warn,
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
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_dot||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwip200003c;
/
