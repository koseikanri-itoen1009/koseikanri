/*============================================================================
* �t�@�C���� : XxccpSalesAllWorkListCO
* �T�v����   : �S�����[�N���X�g�i�c�ƃV�X�e���p�j�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-08-10 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxccp.xxccp010A01j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/*******************************************************************************
 * �S�����[�N���X�g�i�c�ƃV�X�e���p�j�̃R���g���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxccpSalesAllWorkListCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /*****************************************************************************
   * ��ʋN�����̏������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    pageContext.removeParameter("WFEBizWorklist");
    pageContext.putParameter("wfPage", "Y");
  }

  /*****************************************************************************
   * ��ʃC�x���g�̏������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);
  }

}
