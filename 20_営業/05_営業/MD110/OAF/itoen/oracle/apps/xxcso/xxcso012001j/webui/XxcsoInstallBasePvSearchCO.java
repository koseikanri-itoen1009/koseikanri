/*============================================================================
* �t�@�C���� : XxcsoInstallBasePvSearchCO
* �T�v����   : �������ėp������ʃR���g���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonConstants;
import itoen.oracle.apps.xxcso.xxcso012001j.util.XxcsoPvCommonUtils;

import java.io.Serializable;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADataBoundValueFireActionURL;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAImageBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.OAWebBeanData;
import oracle.apps.fnd.framework.webui.beans.layout.OACellFormatBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageStyledTextBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.table.OATableBean;
import oracle.cabo.ui.data.DictionaryData;

/*******************************************************************************
 * �������ėp������ʂ̃R���g���[���N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBasePvSearchCO extends OAControllerImpl
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

    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    XxcsoUtils.debug(pageContext, "[START]");

    // URL����p�����[�^���擾���܂��B
    String execMode
      =  pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String viewId
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

    // �J�ڌ���ʂ���̃��b�Z�[�W���擾���A�ݒ肷��
    XxcsoUtils.showDialogMessage(pageContext);

    // �|�b�v���X�g�̏��������s��
    OAMessageChoiceBean choiceBean
      = (OAMessageChoiceBean) webBean.findChildRecursive("ViewName");
    if ( choiceBean != null) 
    {
      choiceBean.setPickListCacheEnabled(false);
    }

    // ���s�敪�ɂ�菈������
    // �����\��
    if ( execMode == null || "".equals(execMode.trim()) )
    {
      // �����\������
      am.invokeMethod("initDetails");
    }
    // �p�[�\�i���C�Y�r���[�쐬��ʁu�K�p����ь������s�v
    else if ( XxcsoPvCommonConstants.EXECUTE_MODE_QUERY.equals(execMode) )
    {
      Serializable[] param1 = { viewId };
      // �����\���ݒ�
      am.invokeMethod("initQueryDetails", param1);

      // �\���s���擾����
      String viewSize = (String) am.invokeMethod("getViewSize", param1);

      Serializable[] param2 = { viewId, pvDisplayMode };
      // �������s
      List searchList
        = (ArrayList) am.invokeMethod("getInstallBaseData", param2);

      // ���b�Z�[�W
      OAException msg = (OAException)am.invokeMethod("getMessage");
      if (msg != null)
      {
        pageContext.putDialogMessage(msg);
      }

      // �����ėp������񐶐�
      this.createInstallBasePv(
        pageContext
       ,webBean
       ,searchList
       ,viewSize
      );

    }

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

    // AM�C���X�^���X�̐���
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    XxcsoUtils.debug(pageContext, "[START]");

    // URL����p�����[�^���擾���܂��B
    String execMode
      =  pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String pvDisplayMode
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String viewId
      =  pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

    // ********************************
    // *****�{�^�������n���h�����O*****
    // ********************************
    // �u�i�ށv�{�^��
    if ( pageContext.getParameter("ForwardButton") != null )
    {
      String selViewId = (String) am.invokeMethod("handleForwardButton");

      // �擾����viewid��querystring�ɐݒ肵�A����ʑJ��
      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            XxcsoPvCommonConstants.EXECUTE_MODE_QUERY
           ,pvDisplayMode
           ,selViewId
          );

      pageContext.forwardImmediately(
        XxcsoPvCommonUtils.getInstallBasePgName(pvDisplayMode)
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    // �u�p�[�\�i���C�Y�v�{�^��
    if ( pageContext.getParameter("PersonalizeButton") != null )
    {
      String selViewId = (String) am.invokeMethod("handlePersonalizeButton");

      HashMap paramMap
        = XxcsoPvCommonUtils.createParam(
            null
           ,pvDisplayMode
           ,selViewId
          );

      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_PV_SEARCH_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );

    }

    // ********************************
    // *****Icon(image)�����n���h�����O
    // ********************************
    // �X�V�A�C�R��
    if ( XxcsoPvCommonConstants.IMAGE_ACTION_NAME.equals(
            pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM))
    )
    {
      String instanceId
        = pageContext.getParameter(
            XxcsoPvCommonConstants.IMAGE_FIRE_ACTION_NAME
          );

      HashMap paramMap = new HashMap(3);
      paramMap.put("CsietInstance_ID", instanceId);
      paramMap.put("CsifpbPageBeanMODE", "0");
      paramMap.put("CsifpbPageEvent", "0");

      // IB��ʂւ̑J��
      pageContext.forwardImmediately(
         XxcsoConstants.FUNC_CSI_SEARCH_PROD
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,paramMap
       ,false
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * �����ėp�������\����ݒ菈��
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   * @param list        �\������ List->Map
   *****************************************************************************
   */
  private void createInstallBasePv(
    OAPageContext pageContext
   ,OAWebBean     webBean
   ,List          list
   ,String        viewSize
  )
  {
    XxcsoUtils.debug(pageContext, "[START]");

    // Table���[�W�������쐬����e���[�W�����̏����擾
    // webBean -> cellformat
    OACellFormatBean cellformatBean
      = (OACellFormatBean)
          webBean.findChildRecursive(
            XxcsoPvCommonConstants.RN_TABLE_LAYOUT_CELL0301
          );

    // Table���[�W�����̑��݃`�F�b�N
    OATableBean tableBeanOld
      = (OATableBean)
          cellformatBean.findChildRecursive(
            XxcsoPvCommonConstants.RN_TABLE
          );

    // ���݂���ꍇ�͍폜����
    if ( tableBeanOld != null ) 
    {
      int tableIndex
        = pageContext.findChildIndex(
            cellformatBean
           ,XxcsoPvCommonConstants.RN_TABLE
          );

      cellformatBean.removeIndexedChild(tableIndex);
    }

    // Table���[�W�����̍쐬;
    OATableBean tableBean
      = (OATableBean)
          createWebBean(
            pageContext
           ,OAWebBeanConstants.TABLE_BEAN
           ,null
           ,XxcsoPvCommonConstants.RN_TABLE
          );

    // �\���s���̐ݒ�
    tableBean.setNumberOfRowsDisplayed(Integer.parseInt(viewSize));
    // ���̐ݒ�
    tableBean.setWidth(XxcsoPvCommonConstants.TABLE_WIDTH);
    DictionaryData tableFormat = new DictionaryData();
    // Table�̏����ݒ�
    if (tableFormat != null)
    {
      // banding�̐ݒ�
      tableFormat.put(TABLE_BANDING_KEY, ROW_BANDING);
      tableBean.setTableFormat(tableFormat);
    }

    // �\���񐔕�messageStyledText��ǉ�����
    int listSize = list.size();
    for (int i = 0; i < listSize; i++)
    {
      HashMap map = (HashMap) list.get(i);

      // *****************
      // messageStyledText
      // *****************
      OAMessageStyledTextBean msgStyledTxt
        = (OAMessageStyledTextBean)
             createWebBean(
                pageContext
               ,OAWebBeanConstants.MESSAGE_STYLED_TEXT_BEAN
               ,null
               ,(String)map.get(XxcsoPvCommonConstants.KEY_ID)
              );

      // �v�����v�g
      msgStyledTxt.setPrompt(
        (String) map.get(XxcsoPvCommonConstants.KEY_NAME)
      );
      // �r���[�C���X�^���X��
      msgStyledTxt.setViewUsageName(XxcsoPvCommonConstants.VIEW_NAME);
      // �r���[����
      msgStyledTxt.setViewAttributeName(
        (String) map.get(XxcsoPvCommonConstants.KEY_ATTR_NAME)
      );
      // �f�[�^�^
      msgStyledTxt.setDataType(
        (String) map.get(XxcsoPvCommonConstants.KEY_DATA_TYPE)
      );

      tableBean.addIndexedChild(msgStyledTxt);
    }

    // �ڍ׃C���[�W�̒ǉ�
    // *****************
    // image
    // *****************
    OAImageBean imageBean
      = (OAImageBean)
           createWebBean(
              pageContext
             ,OAWebBeanConstants.IMAGE_BEAN
             ,null
             ,"detail"
            );
    // ���x����
    imageBean.setLabel(             XxcsoPvCommonConstants.IMAGE_LABEL );
    // �r���[�C���X�^���X��
    imageBean.setViewUsageName(     XxcsoPvCommonConstants.VIEW_NAME );
    // �r���[������
    imageBean.setViewAttributeName( XxcsoPvCommonConstants.IMAGE_VIEW_ATTR );
    // image�̃\�[�X
    imageBean.setSource(            XxcsoPvCommonConstants.IMAGE_SOURCE );
    // onmouseover���̃o���[���w���v
    imageBean.setShortDesc(         XxcsoPvCommonConstants.IMAGE_SHORT_DESC );
    // image�̍���
    imageBean.setHeight(            XxcsoPvCommonConstants.IMAGE_HEIGHT );
    // image�̕�
    imageBean.setWidth(             XxcsoPvCommonConstants.IMAGE_WIDTH );

    // fireAction�̐ݒ�
    Hashtable params = new Hashtable(1);
    params.put("param1", pageContext.getRootRegionCode());

    Hashtable paramWithBinds = new Hashtable(1);
    paramWithBinds.put(
      XxcsoPvCommonConstants.IMAGE_FIRE_ACTION_NAME
     ,new OADataBoundValueFireActionURL(
        (OAWebBeanData) webBean
       ,XxcsoPvCommonConstants.IMAGE_FIRE_ACTION_PARAM
      )
    );
    imageBean.setFireActionForSubmit(
      XxcsoPvCommonConstants.IMAGE_ACTION_NAME
     ,params
     ,paramWithBinds
     ,false
     ,false
    );

    tableBean.addIndexedChild(imageBean);
      
    // ���݂̃y�[�W�ɒǉ�����
    cellformatBean.addIndexedChild(tableBean);

    XxcsoUtils.debug(pageContext, "[END]");

  }
}
