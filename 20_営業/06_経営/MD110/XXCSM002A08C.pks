CREATE OR REPLACE PACKAGE XXCSM002A08C AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A08C(spec)
 * Description      : ���̾��ʷײ�(�Ķȸ���)�����å��ꥹ�Ƚ���
 * MD.050           : ���̾��ʷײ�(�Ķȸ���)�����å��ꥹ�Ƚ��� MD050_CSM_002_A08
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 *
 *  main                �ڥ��󥫥��ȼ¹ԥե�������Ͽ�ץ��������
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/15    1.0   S.son        ��������
 *
 *****************************************************************************************/
--
  --���󥫥��ȼ¹ԥե�������Ͽ�ץ�������
  PROCEDURE main(
    errbuf                 OUT    NOCOPY VARCHAR2,         --   ���顼��å�����
    retcode                OUT    NOCOPY VARCHAR2,         --   ���顼������
    iv_subject_year        IN     VARCHAR2,                --   �о�ǯ��
    iv_location_cd         IN     VARCHAR2,                --   ����������
    iv_hierarchy_level     IN     VARCHAR2                 --   ����
  );
END XXCSM002A08C;
/
