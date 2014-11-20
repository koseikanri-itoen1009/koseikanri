/*============================================================================
* �t�@�C���� : XxcsoSpDecisionSearchCO
* �T�v����   : SP�ꌈ��������ʃR���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCS����_    �V�K�쐬
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
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionConstants;
import java.io.Serializable;
import com.sun.java.util.collections.HashMap;

/*******************************************************************************
 * SP�ꌈ��������ʂ̃R���g���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSearchCO extends OAControllerImpl
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
      XxcsoUtils.unexpected(pageContext, "am instance is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    String searchClass = pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    XxcsoUtils.debug(pageContext, "Search Class = " + searchClass);
    if ( searchClass == null )
    {
      XxcsoUtils.unexpected(pageContext, "ExecuteMode is null");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    Serializable[] params =
    {
      searchClass
    };
    
    am.invokeMethod("initDetails", params);

    setVAlignMiddle(webBean);

    XxcsoUtils.setAdvancedTableRows(
      pageContext
     ,webBean
     ,"ResultAdvTblRN"
     ,"XXCSO1_VIEW_SIZE_020_A01_02"
    );
    
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

    if ( pageContext.getParameter("SearchButton") != null )
    {
      am.invokeMethod("handleSearchButton");
    }

    if ( pageContext.getParameter("ClearButton") != null )
    {
      am.invokeMethod("handleClearButton");
    }

    if ( pageContext.getParameter("BackButton") != null )
    {
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_OA_HOME_PAGE
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,null
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    if ( pageContext.getParameter("CopyButton") != null )
    {
      String spDecisionHeaderId
        = (String)am.invokeMethod("handleCopyButton");

      HashMap params = new HashMap(2);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoSpDecisionConstants.COPY_MODE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,spDecisionHeaderId
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.EXECUTE_MODE)
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

    if ( pageContext.getParameter("DetailButton") != null )
    {
      String spDecisionHeaderId
        = (String)am.invokeMethod("handleDetailButton");      

      HashMap params = new HashMap(2);
      params.put(
        XxcsoConstants.EXECUTE_MODE
       ,XxcsoSpDecisionConstants.DETAIL_MODE
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY1
       ,spDecisionHeaderId
      );
      params.put(
        XxcsoConstants.TRANSACTION_KEY2
        ,pageContext.getParameter(XxcsoConstants.EXECUTE_MODE)
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

  /*****************************************************************************
   * ���C�A�E�g�����i�Z���^�����O�j���s���܂��B
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  private void setVAlignMiddle(OAWebBean webBean)
  {
    String[] objects = XxcsoSpDecisionConstants.CENTERING_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findChildRecursive(objects[i]);

      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setVAlign("middle");
      }
    }
  }

}
