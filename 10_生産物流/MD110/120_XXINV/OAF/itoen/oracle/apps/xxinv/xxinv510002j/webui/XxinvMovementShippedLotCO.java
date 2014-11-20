/*============================================================================
* �t�@�C���� : XxinvMovementShippedLotCO
* �T�v����   : �o�Ƀ��b�g���׉�ʃR���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-11 1.0  �ɓ��ЂƂ�   �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510002j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxinv.util.XxinvConstants;

import java.io.Serializable;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
/***************************************************************************
 * �o�Ƀ��b�g���׉�ʃR���g���[���N���X�ł��B
 * @author  ORACLE �ɓ� �ЂƂ�
 * @version 1.0
 ***************************************************************************
 */
public class XxinvMovementShippedLotCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);
    
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�����������Ă��Ȃ��ꍇ
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �`�F�b�N�{�^�����������ꂽ�ꍇ
      if ((pageContext.getParameter("Check") != null) ||
          (pageContext.getParameter("Check1") != null)) 
      {
        // �������s��Ȃ��B

      // �K�p�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("Go") != null)) 
      {
        // �������s��Ȃ�

      // �_�C�A���O��ʂ�NO�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("No") != null)) 
      {
        // �������s��Ȃ�

      // �_�C�A���O��ʂ�YES�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("Yes") != null)) 
      {
        // �o�^����
        am.invokeMethod("entryDataShipped");
        
      // �����\���̏ꍇ
      } else
      {
        // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
        TransactionUnitHelper.startTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510002J);

        // �p�����[�^�擾      
        HashMap searchParams = new HashMap();
        searchParams.put("movLineId",      pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_LINE_ID)); // �ړ�����ID
        searchParams.put("productFlg",     pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG));       // ���i���ʋ敪
        searchParams.put("recordTypeCode", XxinvConstants.RECORD_TYPE_20);                                         // ���R�[�h�^�C�v  20�F�o�Ɏ���
        searchParams.put("updateFlag", pageContext.getParameter(XxinvConstants.URL_PARAM_UPDATE_FLAG));

        // �����ݒ�
        Serializable params[] = { searchParams };
        // �����^�ݒ�
        Class[] parameterTypes = { HashMap.class };
        // �����������s
        am.invokeMethod("initialize", params, parameterTypes);
      }
            
    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxinvConstants.TXN_XXINV510002J, true))
      { 
        // �y���ʏ����z�G���[�_�C�A���O��ʂ֑J��
        pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));
      } 
    }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    try
    {
      super.processFormRequest(pageContext, webBean);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
     
      // �s�}���{�^���������ꂽ�ꍇ
      if (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �s�ǉ��������s
        am.invokeMethod("addRow");
        
      // ����{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Return") != null) 
      {
        String actualFlag  = pageContext.getParameter(XxinvConstants.URL_PARAM_ACTUAL_FLAG);        // ���уf�[�^�敪
        String productFlag = pageContext.getParameter(XxinvConstants.URL_PARAM_PRODUCT_FLAG);       // ���i���ʋ敪
        String searchlinId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_LINE_ID); // �ړ�����ID
        String searchHdrId = pageContext.getParameter(XxinvConstants.URL_PARAM_SEARCH_MOV_ID);      // �ړ��w�b�_ID
        String peoplecode  = pageContext.getParameter(XxinvConstants.URL_PARAM_PEOPLE_CODE);        // �]�ƈ��敪
        String updateFlag  = pageContext.getParameter("UpdateFlag");                                // �X�V�t���O

        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxinvConstants.URL_PARAM_ACTUAL_FLAG,        actualFlag);  // ���уf�[�^�敪
        pageParams.put(XxinvConstants.URL_PARAM_PRODUCT_FLAG,       productFlag); // ���i���ʋ敪
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_LINE_ID, searchlinId); // �ړ�����ID
        pageParams.put(XxinvConstants.URL_PARAM_SEARCH_MOV_ID, searchHdrId);      // �ړ��w�b�_ID
        pageParams.put(XxinvConstants.URL_PARAM_PEOPLE_CODE, peoplecode);         // �]�ƈ��敪
        pageParams.put(XxinvConstants.URL_PARAM_UPDATE_FLAG, XxinvConstants.PROCESS_FLAG_U); // �X�V�t���O
        pageParams.put(XxinvConstants.URL_PARAM_PREV_URL, XxinvConstants.URL_XXINV510002J_1); // ���URL

        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxinvConstants.TXN_XXINV510002J);
          
        // ���o�Ɏ��і��׉�ʂ�
        pageContext.setForwardURL(
          XxinvConstants.URL_XXINV510001JL,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);

      // �`�F�b�N�{�^�����������ꂽ�ꍇ
      } else if ((pageContext.getParameter("Check") != null) ||
                  (pageContext.getParameter("Check1") != null)) 
      {
        // ���b�g�`�F�b�N�������s
        am.invokeMethod("checkLot");

      // �K�p�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("Go") != null)
      {
        // ���b�g�`�F�b�N�������s
        am.invokeMethod("checkLot");
        
        // �G���[�`�F�b�N�������s
        String retCode = (String)am.invokeMethod("checkError");

        // �x���`�F�b�N�������s
        HashMap msg = (HashMap)am.invokeMethod("checkWarningShipped");

        String[] lotRevErrFlg     = (String[])msg.get("lotRevErrFlg");     // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
        String[] minusErrFlg      = (String[])msg.get("minusErrFlg");      // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O 
        String[] exceedErrFlg     = (String[])msg.get("exceedErrFlg");     // �����\�݌ɐ����߃`�F�b�N�G���[�t���O
        String[] itemName         = (String[])msg.get("itemName");         // �i�ږ�
        String[] lotNo            = (String[])msg.get("lotNo");            // ���b�gNo
        String[] shipToLocCode    = (String[])msg.get("shipToLocCode");    // ���ɐ�R�[�h
        String[] revDate          = (String[])msg.get("revDate");          // �t�]���t
        String[] manufacturedDate = (String[])msg.get("manufacturedDate"); // �����N����
        String[] koyuCode         = (String[])msg.get("koyuCode");         // �ŗL�L��
        String[] stock            = (String[])msg.get("stock");            // �莝����
        String[] shippedLocName   = (String[])msg.get("shippedLocName");   // �o�ɐ�ۊǑq�ɖ�

        // �_�C�A���O��ʕ\���p���b�Z�[�W
        StringBuffer pageHeaderText = new StringBuffer(100);

        for(int i = 0 ; i < lotRevErrFlg.length ; i++)
        {
          // ���b�g�t�]�h�~�`�F�b�N�ŃG���[�̏ꍇ
          if (XxcmnConstants.STRING_Y.equals(lotRevErrFlg[i]))
          {
            // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
            XxcmnUtility.newLineAppend(pageHeaderText);

            // ���b�g�t�]�h�~�x�����b�Z�[�W�擾
            MessageToken[] tokens = { new MessageToken(XxinvConstants.TOKEN_ITEM,     itemName[i]),
                                      new MessageToken(XxinvConstants.TOKEN_LOT,      lotNo[i]),
                                      new MessageToken(XxinvConstants.TOKEN_LOCATION, shipToLocCode[i]),
                                      new MessageToken(XxinvConstants.TOKEN_REVDATE,  revDate[i])};              
            pageHeaderText.append(
              pageContext.getMessage(
                XxcmnConstants.APPL_XXINV, 
                XxinvConstants.XXINV10130,
                tokens));
          }

          // �}�C�i�X�݌Ƀ`�F�b�N�ŃG���[�̏ꍇ
          if (XxcmnConstants.STRING_Y.equals(minusErrFlg[i]))
          {
            // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
            XxcmnUtility.newLineAppend(pageHeaderText);

            // �}�C�i�X�݌Ƀ`�F�b�N�x�����b�Z�[�W�擾
            MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_ITEM,  itemName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_LOT,   lotNo[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_DATE,  manufacturedDate[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_MARK,  koyuCode[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_STOCK, stock[i])};
            pageHeaderText.append(
              pageContext.getMessage(
                XxcmnConstants.APPL_XXCMN, 
                XxcmnConstants.XXCMN00026,
                tokens));
          }

          // �����\�݌ɐ����߃`�F�b�N�ŃG���[�̏ꍇ
          if (XxcmnConstants.STRING_Y.equals(exceedErrFlg[i]))
          {
            // �x�����b�Z�[�W���������݂���ꍇ�A���s�R�[�h��ǉ�
            XxcmnUtility.newLineAppend(pageHeaderText);

            // �����\�݌ɐ����߃`�F�b�N�x�����b�Z�[�W�擾
            MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_LOCATION,  shippedLocName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_ITEM,      itemName[i]),
                                      new MessageToken(XxcmnConstants.TOKEN_LOT,       lotNo[i])};
            pageHeaderText.append(
              pageContext.getMessage(
                XxcmnConstants.APPL_XXCMN, 
                XxcmnConstants.XXCMN10110,
                tokens));
          }
        }

        // �x�����b�Z�[�W�̂���ꍇ�A�_�C�A���O��\��
        if (pageHeaderText.length() > 0)
        {
          // ���C�����b�Z�[�W�쐬 
          MessageToken[] mainTokens = new MessageToken[1];
          mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, pageHeaderText.toString());

          OAException mainMessage = new OAException(
                                          XxcmnConstants.APPL_XXCMN,
                                          XxcmnConstants.XXCMN00025,
                                          mainTokens);

                                            
          // �_�C�A���O���b�Z�[�W��\��
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxinvConstants.URL_XXINV510002J_1,
            XxinvConstants.URL_XXINV510002J_1,
            "Yes",
            "No",
            "Yes",
            "No",
            null);          
        }
        if (XxcmnConstants.STRING_TRUE.equals(retCode))
        {
          // �o�^����
          am.invokeMethod("entryDataShipped");
        }
      }

    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
