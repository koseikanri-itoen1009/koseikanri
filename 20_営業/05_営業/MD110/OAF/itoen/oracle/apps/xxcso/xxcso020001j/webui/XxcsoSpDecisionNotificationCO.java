/*============================================================================
* �t�@�C���� : XxcsoSpDecisionNotificationCO
* �T�v����   : SP�ꌈ�ʒm��ʃR���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-17 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.webui;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionConstants;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * SP�ꌈ�ʒm��ʂ̃R���g���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionNotificationCO extends OAControllerImpl
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

    XxcsoUtils.debug(pageContext, "[START]");

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    String notifyId = pageContext.getParameter("NtfId");
    if ( notifyId == null )
    {
      XxcsoUtils.unexpected(pageContext, "ntfId instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    Serializable[] params =
    {
      notifyId
    };
    
    am.invokeMethod("initDetails", params);

    XxcsoUtils.debug(pageContext, "[END]");
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

    XxcsoUtils.debug(pageContext, "[START]");

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    if ( "SpDecisionLink".equals(
           pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM) )
       )
    {
      String spDecisionHeaderId
        = pageContext.getParameter("SpDecisionHeaderId");

      XxcsoUtils.debug(
        pageContext
       ,"sp_decision_header_id = " + spDecisionHeaderId
      );
      
      HashMap params = new HashMap(2);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoSpDecisionConstants.DETAIL_MODE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,spDecisionHeaderId
      );

      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_SP_DECISION_REGIST_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,params
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    XxcsoUtils.debug(pageContext, "[END]");
  }

}
