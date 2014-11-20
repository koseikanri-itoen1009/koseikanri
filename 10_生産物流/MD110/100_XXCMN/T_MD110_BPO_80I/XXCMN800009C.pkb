CREATE OR REPLACE PACKAGE BODY xxcmn800009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn800009c(body)
 * Description      : �����\���}�X�^�C���^�[�t�F�[�X(Outbound)
 * MD.050           : �}�X�^�C���^�t�F�[�X T_MD050_BPO_800
 * MD.070           : �����\���}�X�^�C���^�t�F�[�X T_MD070_BPO_80I
 * Version          : 1.4
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  get_logi_mst           �����\���}�X�^�擾�v���V�[�W�� (I-1)
 *  output_csv             CSV�t�@�C���o�̓v���V�[�W�� (I-2)
 *  upd_last_update        �ŏI�X�V�����t�@�C���X�V�v���V�[�W�� (I-3)
 *  wf_notif               Workflow�ʒm�v���V�[�W�� (I-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/15    1.0  Oracle �Ŗ� ���\  ����쐬
 *  2008/05/01    1.1  Oracle �Ŗ� ���\  �ύX�v��#11�Ή�
 *  2008/05/15    1.2  Oracle �Ŗ� ���\  �����ύX�v��#62�Ή�
 *  2008/06/12    1.3  Oracle �ۉ�       ���t���ڏ����ύX
 *  2008/09/18    1.4  Oracle �勴 �F�Y  T_S_460,T_S_575�Ή�
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
  gn_target_cnt    NUMBER;        -- �Ώی���
  gn_normal_cnt    NUMBER;        -- ���팏��
  gn_error_cnt     NUMBER;        -- �G���[����
  gn_warn_cnt      NUMBER;        -- �X�L�b�v����
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
  get_prof_expt       EXCEPTION;      -- �v���t�@�C���擾�G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcmn800009c';      -- �p�b�P�[�W��
  gv_xxcmn            CONSTANT VARCHAR2(100) := 'XXCMN';             -- �A�v���P�[�V�����Z�k��
  gv_prof_err         CONSTANT VARCHAR2(100) := 'APP-XXCMN-10002';   -- �v���t�@�C���擾�G���[
  gv_get_date_err     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10036';   -- �f�[�^�擾�G���[
  gv_file_pass_err    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10113';   -- �t�@�C���p�X�s���G���[
  gv_file_pass_no_err CONSTANT VARCHAR2(100) := 'APP-XXCMN-10119';   -- �t�@�C���p�XNULL�G���[
  gv_file_name_err    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10114';   -- �t�@�C�����s���G���[
  gv_file_name_no_err CONSTANT VARCHAR2(100) := 'APP-XXCMN-10120';   -- �t�@�C����NULL�G���[
  gv_file_priv_err    CONSTANT VARCHAR2(100) := 'APP-XXCMN-10115';   -- �t�@�C���A�N�Z�X�����G���[
  gv_last_update_err  CONSTANT VARCHAR2(100) := 'APP-XXCMN-10116';   -- �ŏI�X�V�����X�V�G���[
  gv_wf_start_err     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10117';   -- Workflow�N���G���[
  gv_wf_ope_div_note  CONSTANT VARCHAR2(100) := 'APP-XXCMN-00013';   -- �����敪
  gv_object_note      CONSTANT VARCHAR2(100) := 'APP-XXCMN-00014';   -- �Ώ�
  gv_address_note     CONSTANT VARCHAR2(100) := 'APP-XXCMN-00015';   -- ����
  gv_last_update_note CONSTANT VARCHAR2(100) := 'APP-XXCMN-00016';   -- �ŏI�X�V����
  gv_syohin_note      CONSTANT VARCHAR2(100) := 'APP-XXCMN-00017';   -- ���i�敪
  gv_item_note        CONSTANT VARCHAR2(100) := 'APP-XXCMN-00018';   -- �i�ڋ敪
  gv_par_date_err     CONSTANT VARCHAR2(100) := 'APP-XXCMN-10083';   -- �p�����[�^���t�^�`�F�b�N
  gv_prof_token       CONSTANT VARCHAR2(100) := 'NG_PROFILE';        -- �v���t�@�C���擾�g�[�N��
  gv_rep_file         CONSTANT VARCHAR2(1)   := '0';                 -- �������ʃ��|�[�g
  gv_csv_file         CONSTANT VARCHAR2(1)   := '1';                 -- CSV�t�@�C��
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- �����\���}�X�^�����i�[���郌�R�[�h
  TYPE logi_mst_rec IS RECORD(
    item_id               ic_item_mst_b.item_id%TYPE,                     -- �i��ID
    item_code             xxcmn_sourcing_rules.item_code%TYPE,            -- �i�ڃR�[�h
    base_code             xxcmn_sourcing_rules.base_code%TYPE,            -- ���_�R�[�h
    ship_to_code          xxcmn_sourcing_rules.ship_to_code%TYPE,         -- �z����R�[�h
    delivery_whse_code    xxcmn_sourcing_rules.delivery_whse_code%TYPE,   -- �o�בq��
    move_from_whse_code1  xxcmn_sourcing_rules.move_from_whse_code1%TYPE, -- �ړ����q��1
    move_from_whse_code2  xxcmn_sourcing_rules.move_from_whse_code2%TYPE, -- �ړ����q��2
    vendor_site_code1     xxcmn_sourcing_rules.vendor_site_code1%TYPE,    -- �d����T�C�g1
    vendor_site_code2     xxcmn_sourcing_rules.vendor_site_code2%TYPE,    -- �d����T�C�g2
    start_date_active     xxcmn_sourcing_rules.start_date_active%TYPE,    -- �K�p�J�n��
    last_update_date      xxcmn_sourcing_rules.last_update_date%TYPE      -- �ŏI�X�V����
  );
--
  -- �����\���}�X�^�����i�[����e�[�u���^�̒�`
  TYPE logi_mst_tbl IS TABLE OF logi_mst_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_logi_mst_tbl    logi_mst_tbl;                          -- �����z��̒�`
  gr_outbound_rec    xxcmn_common_pkg.outbound_rec;         -- �t�@�C�����̃��R�[�h�̒�`
  gd_sysdate         DATE;                                  -- �V�X�e�����ݓ��t
--
  /**********************************************************************************
   * Procedure Name   : get_logi_mst
   * Description      : �����\���}�X�^�擾(I-1)
   ***********************************************************************************/
  PROCEDURE get_logi_mst(
    iv_wf_ope_div         IN  VARCHAR2,            -- �����敪
    iv_wf_class           IN  VARCHAR2,            -- �Ώ�
    iv_wf_notification    IN  VARCHAR2,            -- ����
    iv_last_update        IN  VARCHAR2,            -- �ŏI�X�V����
    iv_syohin             IN  VARCHAR2,            -- ���i�敪
    iv_item               IN  VARCHAR2,            -- �i�ڋ敪
    ov_errbuf             OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode            OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg             OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_logi_mst'; -- �v���O������
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
    cv_item_div     CONSTANT VARCHAR2(100) := '���i�敪'; -- �v���t�@�C�����i�敪
    cv_article_div  CONSTANT VARCHAR2(100) := '�i�ڋ敪'; -- �v���t�@�C���i�ڋ敪
    cv_item_code    CONSTANT VARCHAR2(100) := 'ZZZZZZZ';    -- �i�ڃR�[�h
--
    -- *** ���[�J���ϐ� ***
    lv_item_div     VARCHAR2(100);      -- �v���t�@�C��'���i�敪'
    lv_article_div  VARCHAR2(100);      -- �v���t�@�C��'�i�ڋ敪'
    ld_last_update  DATE;               -- �ŏI�X�V����
--
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
    -- �t�@�C���o�͏��擾�֐��Ăяo��
    xxcmn_common_pkg.get_outbound_info(iv_wf_ope_div,     -- �����敪
                                       iv_wf_class,       -- �Ώ�
                                       iv_wf_notification,-- ����
                                       gr_outbound_rec,   -- �t�@�C�����̃��R�[�h�^�ϐ�
                                       lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                                       lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                                       lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_get_date_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- �v���t�@�C���l�̎擾
    lv_item_div := FND_PROFILE.VALUE('XXCMN_ITEM_DIV');
--
    -- �擾�ł��Ȃ������ꍇ�̓G���[
    IF (lv_item_div IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_prof_err,
                                            gv_prof_token,
                                            cv_item_div);
      lv_errbuf := lv_errmsg;
      RAISE get_prof_expt;
    END IF;
--
    -- �v���t�@�C���l�̎擾
    lv_article_div := FND_PROFILE.VALUE('XXCMN_ARTICLE_DIV');
--
    -- �擾�ł��Ȃ������ꍇ�̓G���[
    IF (lv_article_div IS NULL) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,
                                            gv_prof_err,
                                            gv_prof_token,
                                            cv_article_div);
      lv_errbuf := lv_errmsg;
      RAISE get_prof_expt;
    END IF;
--
    -- �p�����[�^'�ŏI�X�V����'��NULL�̏ꍇ
    IF (iv_last_update IS NULL) THEN
      ld_last_update := gr_outbound_rec.file_last_update_date;
    -- �p�����[�^'�ŏI�X�V����'��NULL�łȂ��ꍇ
    ELSE
      ld_last_update := FND_DATE.STRING_TO_DATE(iv_last_update, 'YYYY/MM/DD HH24:MI:SS');
    END IF;
--
    SELECT xsr1.item_id,                   -- �i��ID
           xsr1.item_code,                 -- �i�ڃR�[�h
           xsr1.base_code,                 -- ���_�R�[�h
           xsr1.ship_to_code,              -- �z����R�[�h
           xsr1.delivery_whse_code,        -- �o�בq��
           xsr1.move_from_whse_code1,      -- �ړ����q��1
           xsr1.move_from_whse_code2,      -- �ړ����q��2
           xsr1.vendor_site_code1,         -- �d����T�C�g1
           xsr1.vendor_site_code2,         -- �d����T�C�g2
           xsr1.start_date_active,         -- �K�p�J�n��
           xsr1.last_update_date           -- �ŏI�X�V����
    BULK COLLECT INTO gt_logi_mst_tbl
    FROM   (SELECT iimb.item_id,                  -- �i��ID
                   xsr.item_code,                 -- �i�ڃR�[�h
                   xsr.base_code,                 -- ���_�R�[�h
                   xsr.ship_to_code,              -- �z����R�[�h
                   xsr.delivery_whse_code,        -- �o�בq��
                   xsr.move_from_whse_code1,      -- �ړ����q��1
                   xsr.move_from_whse_code2,      -- �ړ����q��2
                   xsr.vendor_site_code1,         -- �d����T�C�g1
                   xsr.vendor_site_code2,         -- �d����T�C�g2
                   xsr.start_date_active,         -- �K�p�J�n��
                   xsr.last_update_date           -- �ŏI�X�V����
           FROM    xxcmn_sourcing_rules    xsr,   -- �����\���A�h�I���}�X�^
                   ic_item_mst_b           iimb,  -- OPM�i�ڃ}�X�^
                   xxcmn_item_categories_v xicv,  -- OPM�i�ڃJ�e�S���������VIEW
                   xxcmn_item_categories_v xicv1
           -- ���i�敪
           WHERE   ((xicv.category_set_name = lv_item_div) AND
                     (xicv.segment1 = NVL(iv_syohin, xicv.segment1)))
           -- �i�ڋ敪
           AND     ((xicv1.category_set_name = lv_article_div) AND
                     (xicv1.segment1 = NVL(iv_item, xicv1.segment1)))
           AND     ((xsr.last_update_date >= ld_last_update) AND
                     (xsr.last_update_date < gd_sysdate))
           AND     iimb.item_no        = xsr.item_code
           AND     iimb.item_id        = xicv.item_id
           AND     iimb.item_id        = xicv1.item_id
           UNION
           SELECT NULL,                          -- �i��ID
                  xsr.item_code,                 -- �i�ڃR�[�h
                  xsr.base_code,                 -- ���_�R�[�h
                  xsr.ship_to_code,              -- �z����R�[�h
                  xsr.delivery_whse_code,        -- �o�בq��
                  xsr.move_from_whse_code1,      -- �ړ����q��1
                  xsr.move_from_whse_code2,      -- �ړ����q��2
                  xsr.vendor_site_code1,         -- �d����T�C�g1
                  xsr.vendor_site_code2,         -- �d����T�C�g2
                  xsr.start_date_active,         -- �K�p�J�n��
                  xsr.last_update_date           -- �ŏI�X�V����
           FROM   xxcmn_sourcing_rules    xsr    -- �����\���A�h�I���}�X�^
           WHERE  xsr.item_code = cv_item_code
           AND    ((xsr.last_update_date >= ld_last_update) AND
                    (xsr.last_update_date < gd_sysdate))) xsr1
    ORDER BY xsr1.item_code, xsr1.base_code, xsr1.ship_to_code, xsr1.start_date_active;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
  EXCEPTION
--
    WHEN get_prof_expt THEN                   --*** �v���t�@�C���擾�G���[ ***
      -- *** �C�ӂŗ�O�������L�q���� ****
      ov_errmsg := lv_errmsg;                                                   --# �C�� #
      ov_errbuf := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;                                            --# �C�� #
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
  END get_logi_mst;
--
  /**********************************************************************************
   * Procedure Name   : output_csv�i���[�v���j
   * Description      : CSV�t�@�C���o��(I-2)
   ***********************************************************************************/
  PROCEDURE output_csv(
    iv_file_type  IN  VARCHAR2,            -- �t�@�C�����
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W                  --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h                    --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W        --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- �v���O������
--
--#######################  �Œ胍�[�J���ϐ��錾�� START   ######################
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
    cv_itoen        CONSTANT VARCHAR2(5)  := 'ITOEN';
    cv_xxcmn_d17    CONSTANT VARCHAR2(3)  := '900';
    cv_b_num        CONSTANT VARCHAR2(2)  := '00';
    cv_sep_com      CONSTANT VARCHAR2(1)  := ',';
-- add start ver1.4
    cv_crlf         CONSTANT VARCHAR2(1)  := CHR(13); -- ���s�R�[�h
-- add end ver1.4
--
    -- *** ���[�J���ϐ� ***
    lf_file_hand    UTL_FILE.FILE_TYPE;    -- �t�@�C���E�n���h���̐錾
    lv_csv_file     VARCHAR2(5000);        -- �o�͏��
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>
--
    -- <�J�[�\����>���R�[�h�^
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
    -- ***        ���[�v�����̋L�q         ***
    -- ***       �������̌Ăяo��          ***
    -- ***************************************
    BEGIN
      -- �t�@�C���p�X���w�肳��Ă��Ȃ��ꍇ
      IF (gr_outbound_rec.directory IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_pass_no_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- �t�@�C�������w�肳��Ă��Ȃ��ꍇ
      ELSIF (gr_outbound_rec.file_name IS NULL) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_name_no_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
--
      -- CSV�t�@�C���֏o�͂���ꍇ
      IF (iv_file_type = gv_csv_file) THEN
        lf_file_hand := UTL_FILE.FOPEN(gr_outbound_rec.directory,
                                       gr_outbound_rec.file_name,
                                       'w');
      END IF;
      -- �����\���}�X�^��񂪎擾�ł��Ă���ꍇ
      IF (gt_logi_mst_tbl.COUNT <> 0) THEN
        <<gt_logi_mst_tbl_loop>>
        FOR i IN gt_logi_mst_tbl.FIRST .. gt_logi_mst_tbl.LAST LOOP
          lv_csv_file   := cv_itoen                                 || cv_sep_com   -- ��Ж�
                        || cv_xxcmn_d17                             || cv_sep_com   -- EOS�f�[�^���
                        || cv_b_num                                 || cv_sep_com   -- �`�[�p�}��
                        || gt_logi_mst_tbl(i).item_code             || cv_sep_com   -- �R�[�h1
                        || gt_logi_mst_tbl(i).base_code             || cv_sep_com   -- �R�[�h2
                        || gt_logi_mst_tbl(i).ship_to_code          || cv_sep_com   -- �R�[�h3
                                                                    || cv_sep_com   -- ����1
                                                                    || cv_sep_com   -- ����2
                                                                    || cv_sep_com   -- ����3
                                                                    || cv_sep_com   -- ���1
                                                                    || cv_sep_com   -- ���2
                                                                    || cv_sep_com   -- ���3
                                                                    || cv_sep_com   -- ���4
                                                                    || cv_sep_com   -- ���5
                                                                    || cv_sep_com   -- ���6
                                                                    || cv_sep_com   -- ���7
                                                                    || cv_sep_com   -- ���8
                                                                    || cv_sep_com   -- ���9
                        || gt_logi_mst_tbl(i).vendor_site_code1     || cv_sep_com   -- ���10
                        || gt_logi_mst_tbl(i).vendor_site_code2     || cv_sep_com   -- ���11
                        || gt_logi_mst_tbl(i).move_from_whse_code1  || cv_sep_com   -- ���12
                        || gt_logi_mst_tbl(i).move_from_whse_code2  || cv_sep_com   -- ���13
                        || gt_logi_mst_tbl(i).delivery_whse_code    || cv_sep_com   -- ���14
                                                                    || cv_sep_com   -- ���15
                                                                    || cv_sep_com   -- ���16
                                                                    || cv_sep_com   -- ���17
                                                                    || cv_sep_com   -- ���18
                                                                    || cv_sep_com   -- ���19
                                                                    || cv_sep_com   -- ���20
                                                                    || cv_sep_com   -- �敪1
                                                                    || cv_sep_com   -- �敪2
                                                                    || cv_sep_com   -- �敪3
                                                                    || cv_sep_com   -- �敪4
                                                                    || cv_sep_com   -- �敪5
                                                                    || cv_sep_com   -- �敪6
                                                                    || cv_sep_com   -- �敪7
                                                                    || cv_sep_com   -- �敪8
                                                                    || cv_sep_com   -- �敪9
                                                                    || cv_sep_com   -- �敪10
                                                                    || cv_sep_com   -- �敪11
                                                                    || cv_sep_com   -- �敪12
                                                                    || cv_sep_com   -- �敪13
                                                                    || cv_sep_com   -- �敪14
                                                                    || cv_sep_com   -- �敪15
                                                                    || cv_sep_com   -- �敪16
                                                                    || cv_sep_com   -- �敪17
                                                                    || cv_sep_com   -- �敪18
                                                                    || cv_sep_com   -- �敪19
                                                                    || cv_sep_com   -- �敪20
                        || TO_CHAR(gt_logi_mst_tbl(i).start_date_active, 'YYYY/MM/DD')
                                                                    || cv_sep_com   -- �K�p�J�n��
                        || TO_CHAR(gt_logi_mst_tbl(i).last_update_date, 'YYYY/MM/DD HH24:MI:SS')
-- mod start ver1.4
--                        ;                                                           -- �X�V����
                        || cv_crlf;                                                 -- �X�V����
-- mod end ver1.4
--
          -- CSV�t�@�C���֏o�͂���ꍇ
          IF (iv_file_type = gv_csv_file) THEN
            UTL_FILE.PUT_LINE(lf_file_hand,lv_csv_file);
          -- �������ʃ��|�[�g�֏o�͂���ꍇ
          ELSE
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lv_csv_file);
          END IF;
--
        END LOOP gt_logi_mst_tbl_loop;
      END IF;
      -- CSV�t�@�C���֏o�͂���ꍇ
      IF (iv_file_type = gv_csv_file) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
--
    EXCEPTION
--
      WHEN UTL_FILE.INVALID_PATH THEN       -- �t�@�C���p�X�s���G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_pass_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN UTL_FILE.INVALID_FILENAME THEN   -- �t�@�C�����s���G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_name_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      WHEN UTL_FILE.ACCESS_DENIED THEN      -- �t�@�C���A�N�Z�X�����G���[
        lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_file_priv_err);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
    END;
--
  --==============================================================
  --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
  --==============================================================
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (UTL_FILE.IS_OPEN(lf_file_hand)) THEN
        UTL_FILE.FCLOSE(lf_file_hand);
      END IF;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : upd_last_update
   * Description      : �ŏI�X�V�����t�@�C���X�V(I-3)
   ***********************************************************************************/
  PROCEDURE upd_last_update(
    iv_wf_ope_div       IN  VARCHAR2,            -- �����敪
    iv_wf_class         IN  VARCHAR2,            -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,            -- ����
    ov_errbuf           OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)     -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_last_update'; -- �v���O������
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
    -- �t�@�C���o�͏��X�V�֐��Ăяo��
    xxcmn_common_pkg.upd_outbound_info(iv_wf_ope_div,     -- �����敪
                                       iv_wf_class,       -- �Ώ�
                                       iv_wf_notification,-- ����
                                       gd_sysdate,        -- �V�X�e�����ݓ��t
                                       lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                                       lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                                       lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_last_update_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
  END upd_last_update;
--
  /**********************************************************************************
   * Procedure Name   : wf_notif
   * Description      : Workflow�ʒm(I-4)
   ***********************************************************************************/
  PROCEDURE wf_notif(
    iv_wf_ope_div       IN  VARCHAR2,           -- �����敪
    iv_wf_class         IN  VARCHAR2,           -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,           -- ����
    ov_errbuf           OUT NOCOPY VARCHAR2,    -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT NOCOPY VARCHAR2,    -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT NOCOPY VARCHAR2)    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'wf_notif'; -- �v���O������
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
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    -- ���[�N�t���[�N���֐��Ăяo��
    xxcmn_common_pkg.wf_start(iv_wf_ope_div,     -- �����敪
                              iv_wf_class,       -- �Ώ�
                              iv_wf_notification,-- ����
                              lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
                              lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
                              lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    -- ���^�[���E�R�[�h�ɃG���[���Ԃ��ꂽ�ꍇ�̓G���[
    IF (lv_retcode = gv_status_error) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_wf_start_err);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --���b�Z�[�W�o�́i�G���[�ȊO�j������K�v������ꍇ�͏������L�q
    --==============================================================
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
  END wf_notif;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_wf_ope_div        IN  VARCHAR2,        -- �����敪
    iv_wf_class          IN  VARCHAR2,        -- �Ώ�
    iv_wf_notification   IN  VARCHAR2,        -- ����
    iv_last_update       IN  VARCHAR2,        -- �ŏI�X�V����
    iv_syohin            IN  VARCHAR2,        -- ���i�敪
    iv_item              IN  VARCHAR2,        -- �i�ڋ敪
    ov_errbuf            OUT NOCOPY VARCHAR2, -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2, -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2) -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
    lc_out_par    VARCHAR2(1000);   -- ���̓p�����[�^�o��
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
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
--
    -- ===============================
    -- ��������
    -- ===============================
--
    -- �J�n���̃V�X�e�����ݓ��t����
    gd_sysdate := SYSDATE;
--
    -- ���̓p�����[�^�̏������ʃ��|�[�g�o��
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_wf_ope_div_note,
                                          'PAR',iv_wf_ope_div);       -- �����敪
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_object_note,
                                          'PAR',iv_wf_class);         -- �Ώ�
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_address_note,
                                          'PAR',iv_wf_notification);  -- ����
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_last_update_note,
                                          'PAR',iv_last_update);      -- �ŏI�X�V����
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_syohin_note,
                                          'PAR',iv_syohin);           -- ���i�敪
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    lc_out_par := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_item_note,
                                          'PAR',iv_item);             -- �i�ڋ敪
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_out_par);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
--
    -- �p�����[�^�`�F�b�N���ʊ֐��Ăяo��
    IF ((iv_last_update IS NOT NULL) AND
       (xxcmn_common_pkg.check_param_date_yyyymmdd(iv_last_update) = 1)) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg(gv_xxcmn,gv_par_date_err);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- �����\���}�X�^�擾 (I-1)
    -- ===============================
    get_logi_mst(
      iv_wf_ope_div,        -- �����敪
      iv_wf_class,          -- �Ώ�
      iv_wf_notification,   -- ����
      iv_last_update,       -- �ŏI�X�V����
      iv_syohin,            -- ���i�敪
      iv_item,              -- �i�ڋ敪
      lv_errbuf,            -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,           -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ���o�f�[�^�̏o��
    -- ===============================
    output_csv(
      gv_rep_file,       -- �������ʃ��|�[�g
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    gn_target_cnt := gt_logi_mst_tbl.COUNT;
--
    -- ===============================
    -- CSV�t�@�C���o�� (I-2)
    -- ===============================
    output_csv(
      gv_csv_file,       -- CSV�t�@�C��
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    gn_normal_cnt := gt_logi_mst_tbl.COUNT;
--
    -- ===============================
    -- �ŏI�X�V�����t�@�C���X�V (I-3)
    -- ===============================
    upd_last_update(
      iv_wf_ope_div,     -- �����敪
      iv_wf_class,       -- �Ώ�
      iv_wf_notification,-- ����
      lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- add start ver1.4
    IF (gn_normal_cnt > 0) THEN
-- add end ver1.4
      -- ===============================
      -- Workflow�ʒm (I-4)
      -- ===============================
      wf_notif(
        iv_wf_ope_div,     -- �����敪
        iv_wf_class,       -- �Ώ�
        iv_wf_notification,-- ����
        lv_errbuf,         -- �G���[�E���b�Z�[�W           --# �Œ� #
        lv_retcode,        -- ���^�[���E�R�[�h             --# �Œ� #
        lv_errmsg);        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt;
      END IF;
-- add start ver1.4
    END IF;
-- add end ver1.4
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
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2,     -- �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT NOCOPY VARCHAR2,     -- ���^�[���E�R�[�h    --# �Œ� #
    iv_wf_ope_div       IN  VARCHAR2,            -- �����敪
    iv_wf_class         IN  VARCHAR2,            -- �Ώ�
    iv_wf_notification  IN  VARCHAR2,            -- ����
    iv_last_update      IN  VARCHAR2,            -- �ŏI�X�V����
    iv_syohin           IN  VARCHAR2,            -- ���i�敪
    iv_item             IN  VARCHAR2             -- �i�ڋ敪
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
      iv_wf_ope_div,         -- �����敪
      iv_wf_class,           -- �Ώ�
      iv_wf_notification,    -- ����
      iv_last_update,        -- �ŏI�X�V����
      iv_syohin,             -- ���i�敪
      iv_item,               -- �i�ڋ敪
      lv_errbuf,             -- �G���[�E���b�Z�[�W           --# �Œ� #
      lv_retcode,            -- ���^�[���E�R�[�h             --# �Œ� #
      lv_errmsg);            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
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
END xxcmn800009c;
/
