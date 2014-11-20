/*============================================================================
* ファイル名 : XxcsoSalesRegistAMImpl
* 概要説明   : 商談決定情報登録／更新画面アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-28 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.jbo.server.ViewLinkImpl;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.xxcso007003j.util.XxcsoSalesRegistConstants;
import itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesHeadersEOImpl;
import itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesLinesVEOImpl;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;

/*******************************************************************************
 * 商談決定情報を登録／更新するためのアプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesRegistAMImpl extends OAApplicationModuleImpl
{
  /**
   *
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesRegistAMImpl()
  {
  }

  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です。
   * @param leadIdStr 商談ID
   *****************************************************************************
   */
  public void initDetails(
    String leadIdStr
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // トランザクションを初期化します。
    rollback();
    
    ///////////////////////////////////
    // 商談概要を初期化します。
    ///////////////////////////////////
    XxcsoSalesOutLineVOImpl outLineVo = getXxcsoSalesOutLineVO1();
    if ( outLineVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesOutLineVOImpl");
    }

    outLineVo.initQuery(leadIdStr);
    initPoplist();

    XxcsoSalesOutLineVORowImpl outLineRow
      = (XxcsoSalesOutLineVORowImpl)outLineVo.first();

    ///////////////////////////////////
    // 商談決定情報ヘッダを初期化します。
    ///////////////////////////////////
    XxcsoSalesHeaderFullVOImpl headerVo = getXxcsoSalesHeaderFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesHeaderFullVOImpl");
    }

    headerVo.initQuery(outLineRow.getLeadId());
    
    if ( headerVo.first() == null )
    {
      XxcsoUtils.debug(txn, "headerRow new record");
      
      // 取得できなかった場合は新規レコードを作成します。
      XxcsoSalesHeaderFullVORowImpl headerRow
        = (XxcsoSalesHeaderFullVORowImpl)headerVo.createRow();
      if ( headerRow == null )
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoSalesHeaderFullVORowImpl"
          );
      }

      // 商談IDをマッピングします。
      headerRow.setLeadId(outLineRow.getLeadId());
      headerVo.insertRow(headerRow);
    }
    else
    {
      XxcsoUtils.debug(txn, "headerRow exist");
      ///////////////////////////////////
      // 各明細行の表示／非表示を設定します。
      ///////////////////////////////////
      XxcsoSalesLineFullVOImpl lineVo = getXxcsoSalesLineFullVO1();
      if ( lineVo == null )
      {
        throw XxcsoMessage.createInstanceLostError("XxcsoSalesLineFullVOImpl");
      }

      XxcsoSalesLineFullVORowImpl lineRow
        = (XxcsoSalesLineFullVORowImpl)lineVo.first();

      while ( lineRow != null )
      {
        setReadOnly(lineRow);
        setLineRender(lineRow);

        lineRow = (XxcsoSalesLineFullVORowImpl)lineVo.next();
      }
    }

    ///////////////////////////////////
    // 承認依頼用のVOを初期化します。
    ///////////////////////////////////
    XxcsoSalesRequestFullVOImpl requestVo = getXxcsoSalesRequestFullVO1();
    if ( requestVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesRequestFullVOImpl");
    }
    XxcsoSalesRequestFullVORowImpl requestRow
      = (XxcsoSalesRequestFullVORowImpl)requestVo.first();

    requestRow = (XxcsoSalesRequestFullVORowImpl)requestVo.createRow();
    requestRow.setLeadId(outLineRow.getLeadId());
    requestRow.setNotifySubject(outLineRow.getNotifySubject());
    requestVo.insertRow(requestRow);
    
    ///////////////////////////////////
    // 通知者リストを初期化します。
    ///////////////////////////////////
    XxcsoSalesNotifyUserSumVOImpl notifySumVo = getXxcsoSalesNotifyUserSumVO1();
    if ( notifySumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSalesNotifyUserSumVOImpl");
    }

    notifySumVo.initQuery(outLineRow.getLeadId());
    XxcsoSalesNotifyUserSumVORowImpl notifySumRow
      = (XxcsoSalesNotifyUserSumVORowImpl)notifySumVo.first();

    ///////////////////////////////////
    // 通知者リスト登録VOを初期化します。
    ///////////////////////////////////
    XxcsoSalesNotifyFullVOImpl notifyVo = getXxcsoSalesNotifyFullVO1();
    if ( notifyVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesNotifyFullVOImpl");
    }
    XxcsoSalesNotifyFullVORowImpl notifyRow
      = (XxcsoSalesNotifyFullVORowImpl)notifyVo.first();
      
    while ( notifySumRow != null )
    {
      notifyRow = (XxcsoSalesNotifyFullVORowImpl)notifyVo.createRow();

      // 初期取得した情報を登録用に設定する。
      notifyRow.setBaseCode(         notifySumRow.getWorkBaseCode()     );
      notifyRow.setBaseName(         notifySumRow.getWorkBaseName()     );
      notifyRow.setEmployeeNumber(   notifySumRow.getEmployeeNumber()   );
      notifyRow.setFullName(         notifySumRow.getFullName()         );
      notifyRow.setPositionName(     notifySumRow.getPositionName()     );
      notifyRow.setPositionSortCode( notifySumRow.getPositionSortCode() );
      notifyRow.setUserName(         notifySumRow.getUserName()         );

      notifyVo.insertRow(notifyRow);
      
      notifySumRow = (XxcsoSalesNotifyUserSumVORowImpl)notifySumVo.next();
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 取消ボタン押下時の処理です。
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    rollback();

    XxcsoUtils.debug(txn, "[END]");
  }
  
  /*****************************************************************************
   * 適用ボタン押下時の処理です。
   *****************************************************************************
   */
  public OAException handleSubmitButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    
    // 適用時の入力チェックを行います。
    List errorList = new ArrayList();
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    boolean modified = false;

    // ヘッダと明細が更新されているかを確認します。
    if ( XxcsoSalesHeadersEOImpl.isModified(txn) )
    {
      modified = true;
    }
    if ( XxcsoSalesLinesVEOImpl.isModified(txn) )
    {
      modified = true;
    }

    if ( ! modified )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }
    
    ///////////////////////////////////
    // インスタンス取得
    ///////////////////////////////////
    XxcsoSalesOutLineVOImpl outLineVo = getXxcsoSalesOutLineVO1();
    if ( outLineVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesOutLineVOImpl");
    }

    XxcsoSalesHeaderFullVOImpl headerVo = getXxcsoSalesHeaderFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesHeaderFullVOImpl");
    }

    XxcsoSalesLineFullVOImpl lineVo = getXxcsoSalesLineFullVO1();
    if ( lineVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesLineFullVOImpl");
    }

    XxcsoSalesOutLineVORowImpl outLineRow
      = (XxcsoSalesOutLineVORowImpl)outLineVo.first();

    String leadNumber = outLineRow.getLeadNumber();

    ///////////////////////////////////
    // 値検証（商談決定情報ヘッダ）
    ///////////////////////////////////
    XxcsoSalesHeaderFullVORowImpl headerRow
      = (XxcsoSalesHeaderFullVORowImpl)headerVo.first();

    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getOtherContent()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_OTHER_CONTENT
         ,0
        );

    ///////////////////////////////////
    // 値検証（商談決定情報明細）
    ///////////////////////////////////
    XxcsoSalesLineFullVORowImpl lineRow
      = (XxcsoSalesLineFullVORowImpl)lineVo.first();

    int index = 0;
    
    while ( lineRow != null )
    {
      index++;
      
      errorList
        = validateLine(
            errorList
           ,lineRow
           ,XxcsoConstants.OPERATION_MODE_NORMAL
           ,index
          );

      lineRow = (XxcsoSalesLineFullVORowImpl)lineVo.next();
    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // 保存処理を実行します。
    commit();

    OAException msg
      = XxcsoMessage.createCompleteMessage(
          XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_INFO +
            XxcsoConstants.TOKEN_VALUE_SEP_LEFT +
            XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER + leadNumber +
            XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_VALUE_SAVE
        );

    XxcsoUtils.debug(txn, "[END]");
    return msg;
  }
  
  /*****************************************************************************
   * 承認依頼ボタン押下時の処理です。
   *****************************************************************************
   */
  public OAException handleRequestButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    // 承認依頼時の入力チェックを行います。
    List errorList = new ArrayList();
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);
    
    ///////////////////////////////////
    // インスタンス取得
    ///////////////////////////////////
    XxcsoSalesOutLineVOImpl outLineVo = getXxcsoSalesOutLineVO1();
    if ( outLineVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesOutLineVOImpl");
    }

    XxcsoSalesHeaderFullVOImpl headerVo = getXxcsoSalesHeaderFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesHeaderFullVOImpl");
    }

    XxcsoSalesLineFullVOImpl lineVo = getXxcsoSalesLineFullVO1();
    if ( lineVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesLineFullVOImpl");
    }

    XxcsoSalesRequestFullVOImpl requestVo = getXxcsoSalesRequestFullVO1();
    if ( requestVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesRequestFullVOImpl");
    }

    XxcsoSalesNotifyFullVOImpl notifyVo = getXxcsoSalesNotifyFullVO1();
    if ( notifyVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesNotifyFullVOImpl");
    }

    XxcsoSalesOutLineVORowImpl outLineRow
      = (XxcsoSalesOutLineVORowImpl)outLineVo.first();

    String leadNumber = outLineRow.getLeadNumber();

    ///////////////////////////////////
    // 値検証（商談決定情報ヘッダ）
    ///////////////////////////////////
    XxcsoSalesHeaderFullVORowImpl headerRow
      = (XxcsoSalesHeaderFullVORowImpl)headerVo.first();

    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getOtherContent()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_OTHER_CONTENT
         ,0
        );
    
    ///////////////////////////////////
    // 値検証（商談決定情報明細）
    ///////////////////////////////////
    XxcsoSalesLineFullVORowImpl lineRow
      = (XxcsoSalesLineFullVORowImpl)lineVo.first();

    boolean existFlag = false;
    int     index     = 0;
    while ( lineRow != null )
    {
      index++;
      
      if ( "Y".equals(lineRow.getNotifyFlag()) )
      {
        existFlag = true;

        errorList
          = validateLine(
              errorList
             ,lineRow
             ,XxcsoConstants.OPERATION_MODE_REQUEST
             ,index
            );
      }
      else
      {
        errorList
          = validateLine(
              errorList
             ,lineRow
             ,XxcsoConstants.OPERATION_MODE_NORMAL
             ,index
            );
      }
      
      lineRow = (XxcsoSalesLineFullVORowImpl)lineVo.next();
    }

    if ( ! existFlag )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00125);

      errorList.add(error);
    }
    
    ///////////////////////////////////
    // 値検証（承認依頼情報）
    ///////////////////////////////////
    XxcsoSalesRequestFullVORowImpl requestRow
      = (XxcsoSalesRequestFullVORowImpl)requestVo.first();

    errorList
      = util.requiredCheck(
          errorList
         ,requestRow.getNotifySubject()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_NOTIFY_SUBJECT
         ,0
        );
    errorList
      = util.checkIllegalString(
          errorList
         ,requestRow.getNotifySubject()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_NOTIFY_SUBJECT
         ,0
        );
    errorList
      = util.checkIllegalString(
          errorList
         ,requestRow.getNotifyComment()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_NOTIFY_COMMENT
         ,0
        );
    errorList
      = util.requiredCheck(
          errorList
         ,requestRow.getApprovalEmployeeNumber()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_APPROVAL_USER
         ,0
        );
    
    ///////////////////////////////////
    // 値検証（通知者リスト）
    ///////////////////////////////////
    XxcsoSalesNotifyFullVORowImpl notifyRow
      = (XxcsoSalesNotifyFullVORowImpl)notifyVo.first();

    existFlag = false;
    while ( notifyRow != null )
    {
      if ( "Y".equals(notifyRow.getNotifiedFlag()) )
      {
        existFlag = true;
      }
      
      notifyRow = (XxcsoSalesNotifyFullVORowImpl)notifyVo.next();
    }

    if ( ! existFlag )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00273);
      
      errorList.add(error);
    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }


    // 操作モードをREQUESTに設定し、保存処理を実行します。
    requestRow.setOperationMode(XxcsoConstants.OPERATION_MODE_REQUEST);
    commit();
    
    OAException msg
      = XxcsoMessage.createCompleteMessage(
          XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_INFO +
            XxcsoConstants.TOKEN_VALUE_SEP_LEFT +
            XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER + leadNumber +
            XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_REQUEST
        );

    XxcsoUtils.debug(txn, "[END]");
    return msg;
  }
  
  /*****************************************************************************
   * 明細行の新規追加ボタン押下時の処理です。
   *****************************************************************************
   */
  public void handleAddRowButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoSalesLineFullVOImpl lineVo = getXxcsoSalesLineFullVO1();
    if ( lineVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesLineFullVOImpl");
    }

    // 新規行を行の最後に追加します。
    XxcsoSalesLineFullVORowImpl lineRow
      = (XxcsoSalesLineFullVORowImpl)lineVo.createRow();
    if ( lineRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSalesLineFullVORowImpl"
        );
    }

    lineRow.setNotifiedCount(new Number(0));
    setReadOnly(lineRow);
    setLineRender(lineRow);

    lineVo.last();
    lineVo.next();
    lineVo.insertRow(lineRow);

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 商品区分変更時の処理です。
   * @param salesLineId 商談決定情報明細ID
   *****************************************************************************
   */
  public void handleSalesClassChangeEvent(
    String salesLineId
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoSalesLineFullVOImpl lineVo = getXxcsoSalesLineFullVO1();
    if ( lineVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesLineFullVOImpl");
    }

    XxcsoSalesLineFullVORowImpl lineRow
      = (XxcsoSalesLineFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      if ( salesLineId.equals(lineRow.getSalesLineId().toString()) )
      {
        // 同じ商談決定情報明細IDの行の各区分の表示／非表示を切り替えます。
        setLineRender(lineRow);
        setLineValue(lineRow);
        break;
      }

      lineRow = (XxcsoSalesLineFullVORowImpl)lineVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 削除アイコン押下時の処理です。
   * @param salesLineId 商談決定情報明細ID
   *****************************************************************************
   */
  public void handleDeleteIconClickEvent(
    String salesLineId
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "touch sales_line_id = " + salesLineId);

    XxcsoSalesLineFullVOImpl lineVo = getXxcsoSalesLineFullVO1();
    if ( lineVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoSalesLineFullVOImpl");
    }

    XxcsoSalesLineFullVORowImpl lineRow
      = (XxcsoSalesLineFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      if ( salesLineId.equals(lineRow.getSalesLineId().toString()) )
      {
        // 同じ商談決定情報明細IDの行を削除します。
        lineVo.removeCurrentRow();
        break;
      }

      lineRow = (XxcsoSalesLineFullVORowImpl)lineVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");
  }
  
  /*****************************************************************************
   * コミット処理です。
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ロールバック処理です。
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ポップリストの初期化処理です。
   *****************************************************************************
   */
   private void initPoplist()
   {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    // ポップリスト用インスタンスを初期化します。
    XxcsoLookupListVOImpl salesClassListVo = getSalesClassListVO();
    if ( salesClassListVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("SalesClassListVO");
    }
    salesClassListVo.initQuery(
      "XXCSO1_SALES_CLASS_TYPE"
     ,"lookup_code"
    );

    XxcsoLookupListVOImpl salesAdoptClassListVo = getSalesAdoptClassListVO();
    if ( salesAdoptClassListVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("SalesAdoptClassListVO");
    }
    salesAdoptClassListVo.initQuery(
      "XXCSO1_SALES_ADOPT_CLASS_TYPE"
     ,"lookup_code"
    );

    XxcsoLookupListVOImpl salesAreaListVo = getSalesAreaListVO();
    if ( salesAreaListVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("SalesAreaListVO");
    }
    salesAreaListVo.initQuery(
      "XXCSO1_SALES_AREA_TYPE"
     ,"lookup_code"
    );

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 商談決定情報明細行の変更可能／不可の設定処理です。
   * @param lineRow 商談決定情報明細行インスタンス
   *****************************************************************************
   */
  private void setReadOnly(
    XxcsoSalesLineFullVORowImpl lineRow
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( lineRow.getNotifiedCount().intValue() == 0 )
    {
      lineRow.setDeleteEnableSwitcher(
        XxcsoSalesRegistConstants.DELETE_ENABLED
      );
      lineRow.setRowReadOnly(Boolean.FALSE);
    }
    else
    {
      lineRow.setDeleteEnableSwitcher(
        XxcsoSalesRegistConstants.DELETE_DISABLED
      );
      lineRow.setRowReadOnly(Boolean.TRUE);
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 商談決定情報明細行の表示／非表示の設定処理です。
   * @param lineRow 商談決定情報明細行インスタンス
   *****************************************************************************
   */
  private void setLineRender(
    XxcsoSalesLineFullVORowImpl lineRow
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    // すべて表示に設定します。
    lineRow.setSalesAdoptClassRender(Boolean.TRUE);
    lineRow.setSalesAreaRender(Boolean.TRUE);
    lineRow.setDelivPriceRender(Boolean.TRUE);
    lineRow.setStoreSalesPriceRender(Boolean.TRUE);
    lineRow.setStoreSalesPriceIncTaxRender(Boolean.TRUE);
    lineRow.setQuotationPriceRender(Boolean.TRUE);

    String salesClassCode = lineRow.getSalesClassCode();
    if ( salesClassCode == null || "".equals(salesClassCode) )
    {
      lineRow.setSalesAdoptClassRender(Boolean.FALSE);
    }
    else
    {
      if ( XxcsoSalesRegistConstants.SALES_CLASS_CAMP.equals(salesClassCode) )
      {
        // 採用区分を非表示に設定します。
        lineRow.setSalesAdoptClassRender(Boolean.FALSE);
      }
      if ( XxcsoSalesRegistConstants.SALES_CLASS_CUT.equals(salesClassCode) )
      {
        // 採用区分、販売対象エリア、店納価格、
        // 売価（税抜）、売価（税込）、建値
        // を非表示に設定します。
        lineRow.setSalesAdoptClassRender(Boolean.FALSE);
        lineRow.setSalesAreaRender(Boolean.FALSE);
        lineRow.setDelivPriceRender(Boolean.FALSE);
        lineRow.setStoreSalesPriceRender(Boolean.FALSE);
        lineRow.setStoreSalesPriceIncTaxRender(Boolean.FALSE);
        lineRow.setQuotationPriceRender(Boolean.FALSE);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 商談決定情報明細行の値の設定処理です。
   * @param lineRow 商談決定情報明細行インスタンス
   *****************************************************************************
   */
  private void setLineValue(
    XxcsoSalesLineFullVORowImpl lineRow
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    String salesClassCode = lineRow.getSalesClassCode();
    if ( salesClassCode == null || "".equals(salesClassCode) )
    {
      // 採用区分をnullに設定します。
      lineRow.setSalesAdoptClassCode(null);
    }
    else
    {
      if ( XxcsoSalesRegistConstants.SALES_CLASS_CAMP.equals(salesClassCode) )
      {
        // 採用区分をnullに設定します。
        lineRow.setSalesAdoptClassCode(null);
      }
      if ( XxcsoSalesRegistConstants.SALES_CLASS_CUT.equals(salesClassCode) )
      {
        // 採用区分、販売対象エリア、店納価格、
        // 売価（税抜）、売価（税込）、建値
        // をnullに設定します。
        lineRow.setSalesAdoptClassCode(null);
        lineRow.setSalesAreaCode(null);
        lineRow.setDelivPrice(null);
        lineRow.setStoreSalesPrice(null);
        lineRow.setStoreSalesPriceIncTax(null);
        lineRow.setQuotationPrice(null);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 商談決定情報明細行の検証処理です。
   * @param lineRow       商談決定情報明細行インスタンス
   * @param operationMode 操作モード
   *****************************************************************************
   */
  private List validateLine(
    List                        errorList
   ,XxcsoSalesLineFullVORowImpl lineRow
   ,String                      operationMode
   ,int                         index
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    // 商品コード
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getInventoryItemCode()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_ITEM_CODE
         ,index
        );
    
    // 店納価格
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getDelivPrice()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_DELIV_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // 売価（税抜）
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getStoreSalesPrice()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_PRICE + 
            XxcsoConstants.TOKEN_VALUE_SEP_LEFT +
            XxcsoSalesRegistConstants.TOKEN_VALUE_NOT_INC_TAX +
            XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,2
         ,6
         ,true
         ,false
         ,false
         ,index
        );

    // 売価（税込）
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getStoreSalesPriceIncTax()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_PRICE + 
            XxcsoConstants.TOKEN_VALUE_SEP_LEFT +
            XxcsoSalesRegistConstants.TOKEN_VALUE_INC_TAX +
            XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,2
         ,6
         ,true
         ,false
         ,false
         ,index
        );
    
    // 建値
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getQuotationPrice()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_QUOTATION_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // 導入条件
    errorList
      = util.checkIllegalString(
          errorList
         ,lineRow.getIntroduceTerms()
         ,XxcsoSalesRegistConstants.TOKEN_VALUE_INTRO_TERMS
         ,index
        );

    // 必須チェック
    if ( XxcsoConstants.OPERATION_MODE_REQUEST.equals(operationMode) )
    {
      String salesClassCode = lineRow.getSalesClassCode();

      errorList
        = util.requiredCheck(
            errorList
           ,lineRow.getSalesClassCode()
           ,XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_CLASS
           ,index
          );
      
      if ( salesClassCode != null && ! "".equals(salesClassCode.trim()) )
      {
        if (
          XxcsoSalesRegistConstants.SALES_CLASS_CAMP.equals(salesClassCode)
           )
        {
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getSalesAreaCode()
               ,XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_AREA
               ,index
              );
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getSalesScheduleDate()
               ,XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_SCHEDULE_DATE
               ,index
              );
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getDelivPrice()
               ,XxcsoSalesRegistConstants.TOKEN_VALUE_DELIV_PRICE
               ,index
              );
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getIntroduceTerms()
               ,XxcsoSalesRegistConstants.TOKEN_VALUE_INTRO_TERMS
               ,index
              );
        }
        else if (
          XxcsoSalesRegistConstants.SALES_CLASS_CUT.equals(salesClassCode)
                )
        {
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getSalesScheduleDate()
               ,XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_SCHEDULE_DATE
               ,index
              );
        }
        else
        {
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getSalesAdoptClassCode()
               ,XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_ADOPT_CLASS
               ,index
              );
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getSalesAreaCode()
               ,XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_AREA
               ,index
              );
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getSalesScheduleDate()
               ,XxcsoSalesRegistConstants.TOKEN_VALUE_SALES_SCHEDULE_DATE
               ,index
              );
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getDelivPrice()
               ,XxcsoSalesRegistConstants.TOKEN_VALUE_DELIV_PRICE
               ,index
              );
        }
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }


  /**
   *
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso007003j.server", "XxcsoSalesRegistAMLocal");
  }

  /**
   *
   * Container's getter for SalesClassListVO
   */
  public XxcsoLookupListVOImpl getSalesClassListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("SalesClassListVO");
  }

  /**
   *
   * Container's getter for SalesAdoptClassListVO
   */
  public XxcsoLookupListVOImpl getSalesAdoptClassListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("SalesAdoptClassListVO");
  }

  /**
   *
   * Container's getter for SalesAreaListVO
   */
  public XxcsoLookupListVOImpl getSalesAreaListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("SalesAreaListVO");
  }

  /**
   * 
   * Container's getter for XxcsoSalesOutLineVO1
   */
  public XxcsoSalesOutLineVOImpl getXxcsoSalesOutLineVO1()
  {
    return (XxcsoSalesOutLineVOImpl)findViewObject("XxcsoSalesOutLineVO1");
  }


  /**
   * 
   * Container's getter for XxcsoSalesHeaderFullVO1
   */
  public XxcsoSalesHeaderFullVOImpl getXxcsoSalesHeaderFullVO1()
  {
    return (XxcsoSalesHeaderFullVOImpl)findViewObject("XxcsoSalesHeaderFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesLineFullVO1
   */
  public XxcsoSalesLineFullVOImpl getXxcsoSalesLineFullVO1()
  {
    return (XxcsoSalesLineFullVOImpl)findViewObject("XxcsoSalesLineFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesHeaderLineVL1
   */
  public ViewLinkImpl getXxcsoSalesHeaderLineVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSalesHeaderLineVL1");
  }





  /**
   * 
   * Container's getter for XxcsoSalesNotifyUserSumVO1
   */
  public XxcsoSalesNotifyUserSumVOImpl getXxcsoSalesNotifyUserSumVO1()
  {
    return (XxcsoSalesNotifyUserSumVOImpl)findViewObject("XxcsoSalesNotifyUserSumVO1");
  }








  /**
   * 
   * Container's getter for XxcsoSalesRequestFullVO1
   */
  public XxcsoSalesRequestFullVOImpl getXxcsoSalesRequestFullVO1()
  {
    return (XxcsoSalesRequestFullVOImpl)findViewObject("XxcsoSalesRequestFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesNotifyFullVO1
   */
  public XxcsoSalesNotifyFullVOImpl getXxcsoSalesNotifyFullVO1()
  {
    return (XxcsoSalesNotifyFullVOImpl)findViewObject("XxcsoSalesNotifyFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesRequestNotifyVL1
   */
  public ViewLinkImpl getXxcsoSalesRequestNotifyVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSalesRequestNotifyVL1");
  }





}