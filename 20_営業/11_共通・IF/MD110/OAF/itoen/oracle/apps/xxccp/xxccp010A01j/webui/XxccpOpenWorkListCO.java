/*============================================================================
* �t�@�C���� : XxccpOpenWorkListCO
* �T�v����   : �I�[�v�����[�N���X�g�R���g���[��
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
import java.io.Serializable;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;

/*******************************************************************************
 * �I�[�v�����[�N���X�g�i�|�[�^���z�[���y�[�W��ʁj�̃R���g���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxccpOpenWorkListCO extends OAControllerImpl
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

    pageContext.putParameter("WFEBizWorklist", "Y");

    String userName = pageContext.getUserName();
    Serializable[] params =
    {
      userName
    };

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    am.invokeMethod("initDetails", params);
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

    if ( pageContext.getParameter("XxccpSalesAllListButton") != null )
    {
      // �E�Ӑؑ�
      pageContext.changeResponsibility("XXCCP_SALES_WORK_LIST","ICX");

      // ��ʑJ��
      pageContext.forwardImmediately(
        "XXCCP010A01J"
       ,OAWebBeanConstants.RESET_MENU_CONTEXT
       ,"XXCCP_SALES_WORK_LIST"
       ,null
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_YES
      );
    }
  }

}
