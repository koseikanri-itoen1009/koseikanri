/*============================================================================
* �t�@�C���� : XxcsoPvCommonUtils
* �T�v����   : �����ėp�����^�p�[�\�i���C�Y�r���[���ʃN���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.util;

import com.sun.java.util.collections.HashMap;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;

/*******************************************************************************
 * �����ėp�����^�p�[�\�i���C�Y�r���[���ʃN���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvCommonUtils 
{

  /*****************************************************************************
   * �������ėp�������PG�����菈��
   * @param  pvDispMode �ėp�����\���敪
   * @return PG��
   *****************************************************************************
   */
  public static String getInstallBasePgName(String pvDispMode)
  {
    String pgName = "";
    if ( XxcsoPvCommonConstants.PV_DISPLAY_MODE_1.equals(pvDispMode) )
    {
      pgName = XxcsoConstants.FUNC_INSTALL_BASE_PV_SEARCH_PG1;
    }
    else
    {
      pgName = XxcsoConstants.FUNC_INSTALL_BASE_PV_SEARCH_PG2;
    }
    return pgName;
  }
  
  /*****************************************************************************
   * ��ʑJ�ڂɕK�v�ȃp�����[�^���쐬���܂�
   * @param execMode   ���s�敪
   * @param pvDispMode �ėp�����\���敪
   * @param viewId     �r���[ID
   * @return URL�Ɉ����n���p�����[�^(HashMap)
   *****************************************************************************
   */
  public static HashMap createParam(
    String execMode
   ,String pvDispMode
   ,String viewId
  )
  {
    HashMap map = new HashMap(3);
    map.put(XxcsoConstants.EXECUTE_MODE, execMode);       // ���s�敪
    map.put(XxcsoConstants.TRANSACTION_KEY1, pvDispMode); // �ėp�����g�p���[�h
    map.put(XxcsoConstants.TRANSACTION_KEY2, viewId);     // �r���[ID
    return map;
  }



}