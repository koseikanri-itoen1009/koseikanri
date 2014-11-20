/*============================================================================
* �t�@�C���� : XxcsoQuoteSearchCO
* �T�v����   : ���ό����R���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS���g    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017006j.webui;

import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso017006j.util.XxcsoQuoteSearchConstants;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * ���ς����������ʂ̃R���g���[���N���X�ł��B
 * @author  SCS���g
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSearchCO extends OAControllerImpl
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
    XxcsoUtils.debug(pageContext, "[START]");
    
    super.processRequest(pageContext, webBean);

    // �����܂�
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }
    //����������
    am.invokeMethod("initDetails");
    
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
    XxcsoUtils.debug(pageContext, "[START]");
    
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // �i�ރ{�^��
    if ( pageContext.getParameter("SearchButton") != null )
    {
      XxcsoUtils.debug(pageContext, "[SearchButton]");
      HashMap retMap = (HashMap)am.invokeMethod("executeSearch");
      XxcsoUtils.debug(pageContext, 
        "QuoteHeaderID : " + retMap.get(XxcsoConstants.TRANSACTION_KEY1));

      // ���ώ�ʂ��擾
      String quoteType = (String)am.invokeMethod("getQuoteType");
      // �J�ڐ�
      String forwardId = null;

      // �̔���p���ϓ��͉�ʂɑJ��
      if ( XxcsoQuoteSearchConstants.QUOTE_TYPE_1.equals(quoteType) ) 
      {
        forwardId = XxcsoConstants.FUNC_QUOTE_SALES_REGIST_PG;
      }
      // �����≮��p���ϓ��͉�ʂɑJ��
      else 
      {
        forwardId = XxcsoConstants.FUNC_QUOTE_STORE_REGIST_PG;
      }
      
      // ���ϓ��͉�ʂɑJ��
      pageContext.forwardImmediately(
        forwardId,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        retMap,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // �����{�^��
    if ( pageContext.getParameter("ClearButton") != null )
    {
      XxcsoUtils.debug(pageContext, "[ClearButton]");
      am.invokeMethod("ClearBtn");
    }

    // �߂�{�^��
    if ( pageContext.getParameter("ReturnButton") != null )
    {
      XxcsoUtils.debug(pageContext, "[ReturnButton]");
      
      //���j���[��ʂɑJ��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
        true,
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }
    
    XxcsoUtils.debug(pageContext, "[END]");
  }
}
