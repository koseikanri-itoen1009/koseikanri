/*============================================================================
* ファイル名 : XxcsoPvSortColumnDefEOImpl
* 概要説明   : 汎用検索ソート定義テーブルエンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS柳平直人  新規作成
* 2009-04-24 1.1  SCS柳平直人  [ST障害T1_626]create時ID採番不正対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;

import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;

import oracle.jbo.AttributeList;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import com.sun.java.util.collections.Iterator;

/*******************************************************************************
 * 汎用検索ソート定義テーブルのエンティティクラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvSortColumnDefEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int SORTCOLUMNDEFID = 0;
  protected static final int VIEWID = 1;
  protected static final int SETUPNUMBER = 2;
  protected static final int COLUMNCODE = 3;
  protected static final int SORTDIRECTIONCODE = 4;
  protected static final int CREATEDBY = 5;
  protected static final int CREATIONDATE = 6;
  protected static final int LASTUPDATEDBY = 7;
  protected static final int LASTUPDATEDATE = 8;
  protected static final int LASTUPDATELOGIN = 9;
  protected static final int REQUESTID = 10;
  protected static final int PROGRAMAPPLICATIONID = 11;
  protected static final int PROGRAMID = 12;
  protected static final int PROGRAMUPDATEDATE = 13;
  protected static final int XXCSOPVDEFEO = 14;


  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvSortColumnDefEOImpl()
  {
  }

  /**
   * 
   * Retrieves the definition object for this instance class.
   */
  public static synchronized EntityDefImpl getDefinitionObject()
  {
    if (mDefinitionObject == null)
    {
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoPvSortColumnDefEO");
    }
    return mDefinitionObject;
  }


  /*****************************************************************************
   * エンティティの作成処理です。
   * @param list 属性リスト
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    super.create(list);

    // 全明細行を取得します。
    EntityDefImpl lineEntityDef
      = XxcsoPvSortColumnDefEOImpl.getDefinitionObject();

    Iterator lineEoIt = lineEntityDef.getAllEntityInstancesIterator(txn);

// 2009/04/24 [ST障害T1_626] Mod Start
//    int lineCount = 0;
//
//    while( lineEoIt.hasNext() )
//    {
//      XxcsoPvSortColumnDefEOImpl lineEo
//        = (XxcsoPvSortColumnDefEOImpl)lineEoIt.next();
//      if ( lineEo.getEntityState() == OAPlsqlEntityImpl.STATUS_NEW )
//      {
//        lineCount--;
//      }
//    }
//
//    lineCount--;
    int minValue = 0;

    while( lineEoIt.hasNext() )
    {
      XxcsoPvSortColumnDefEOImpl lineEo
        = (XxcsoPvSortColumnDefEOImpl)lineEoIt.next();
      int sortColumnDefId = lineEo.getSortColumnDefId().intValue();

      if ( minValue > sortColumnDefId )
      {
        minValue = sortColumnDefId;
      }
    }
    minValue--;
    XxcsoUtils.debug(txn, "new sortColumnDefId:" + minValue);
// 2009/04/24 [ST障害T1_626] Mod End

    // 仮の値を設定します。
    // PKなので被らないように設定します。
// 2009/04/24 [ST障害T1_626] Mod Start
//    setSortColumnDefId(new Number(lineCount));
    setSortColumnDefId(new Number(minValue));
// 2009/04/24 [ST障害T1_626] Mod End

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * レコード作成処理です。
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    EntityDefImpl headerEntityDef = XxcsoPvDefEOImpl.getDefinitionObject();

    // 全ヘッダ行を取得します。
    Iterator headerEoIt = headerEntityDef.getAllEntityInstancesIterator(txn);

    Number viewId = null;
    
    while ( headerEoIt.hasNext() )
    {
      XxcsoPvDefEOImpl headerEo  = (XxcsoPvDefEOImpl)headerEoIt.next();

      if ( headerEo.getEntityState() == OAPlsqlEntityImpl.STATUS_NEW )
      {
        // 新規作成の場合のみビューIDを設定します。
        viewId = headerEo.getViewId();
        setViewId(viewId);
        break;
      }
    }

    // 登録する直前でシーケンス値を払い出します。
    Number sortColumnDefId
      = getOADBTransaction().getSequenceValue("XXCSO_PV_SORT_COLUMN_DEF_S01");

    setSortColumnDefId(sortColumnDefId);

    super.insertRow();

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * レコードロック処理です。
   * ディティールのテーブルなので空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * レコード更新処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.updateRow
   *****************************************************************************
   */
  public void updateRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    super.updateRow();

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード削除処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.deleteRow
   *****************************************************************************
   */
  public void deleteRow()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    super.deleteRow();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /**
   * 
   * Gets the attribute value for SortColumnDefId, using the alias name SortColumnDefId
   */
  public Number getSortColumnDefId()
  {
    return (Number)getAttributeInternal(SORTCOLUMNDEFID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SortColumnDefId
   */
  public void setSortColumnDefId(Number value)
  {
    setAttributeInternal(SORTCOLUMNDEFID, value);
  }

  /**
   * 
   * Gets the attribute value for ViewId, using the alias name ViewId
   */
  public Number getViewId()
  {
    return (Number)getAttributeInternal(VIEWID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ViewId
   */
  public void setViewId(Number value)
  {
    setAttributeInternal(VIEWID, value);
  }

  /**
   * 
   * Gets the attribute value for SetupNumber, using the alias name SetupNumber
   */
  public Number getSetupNumber()
  {
    return (Number)getAttributeInternal(SETUPNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SetupNumber
   */
  public void setSetupNumber(Number value)
  {
    setAttributeInternal(SETUPNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ColumnCode, using the alias name ColumnCode
   */
  public String getColumnCode()
  {
    return (String)getAttributeInternal(COLUMNCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ColumnCode
   */
  public void setColumnCode(String value)
  {
    setAttributeInternal(COLUMNCODE, value);
  }

  /**
   * 
   * Gets the attribute value for SortDirectionCode, using the alias name SortDirectionCode
   */
  public String getSortDirectionCode()
  {
    return (String)getAttributeInternal(SORTDIRECTIONCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SortDirectionCode
   */
  public void setSortDirectionCode(String value)
  {
    setAttributeInternal(SORTDIRECTIONCODE, value);
  }

  /**
   * 
   * Gets the attribute value for CreatedBy, using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CreationDate, using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateDate, using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateLogin, using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for RequestId, using the alias name RequestId
   */
  public Number getRequestId()
  {
    return (Number)getAttributeInternal(REQUESTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RequestId
   */
  public void setRequestId(Number value)
  {
    setAttributeInternal(REQUESTID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramApplicationId, using the alias name ProgramApplicationId
   */
  public Number getProgramApplicationId()
  {
    return (Number)getAttributeInternal(PROGRAMAPPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramApplicationId
   */
  public void setProgramApplicationId(Number value)
  {
    setAttributeInternal(PROGRAMAPPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramId, using the alias name ProgramId
   */
  public Number getProgramId()
  {
    return (Number)getAttributeInternal(PROGRAMID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramId
   */
  public void setProgramId(Number value)
  {
    setAttributeInternal(PROGRAMID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramUpdateDate, using the alias name ProgramUpdateDate
   */
  public Date getProgramUpdateDate()
  {
    return (Date)getAttributeInternal(PROGRAMUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramUpdateDate
   */
  public void setProgramUpdateDate(Date value)
  {
    setAttributeInternal(PROGRAMUPDATEDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SORTCOLUMNDEFID:
        return getSortColumnDefId();
      case VIEWID:
        return getViewId();
      case SETUPNUMBER:
        return getSetupNumber();
      case COLUMNCODE:
        return getColumnCode();
      case SORTDIRECTIONCODE:
        return getSortDirectionCode();
      case CREATEDBY:
        return getCreatedBy();
      case CREATIONDATE:
        return getCreationDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      case REQUESTID:
        return getRequestId();
      case PROGRAMAPPLICATIONID:
        return getProgramApplicationId();
      case PROGRAMID:
        return getProgramId();
      case PROGRAMUPDATEDATE:
        return getProgramUpdateDate();
      case XXCSOPVDEFEO:
        return getXxcsoPvDefEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SORTCOLUMNDEFID:
        setSortColumnDefId((Number)value);
        return;
      case VIEWID:
        setViewId((Number)value);
        return;
      case SETUPNUMBER:
        setSetupNumber((Number)value);
        return;
      case COLUMNCODE:
        setColumnCode((String)value);
        return;
      case SORTDIRECTIONCODE:
        setSortDirectionCode((String)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((Number)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      case REQUESTID:
        setRequestId((Number)value);
        return;
      case PROGRAMAPPLICATIONID:
        setProgramApplicationId((Number)value);
        return;
      case PROGRAMID:
        setProgramId((Number)value);
        return;
      case PROGRAMUPDATEDATE:
        setProgramUpdateDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }



  /**
   * 
   * Gets the associated entity XxcsoPvDefEOImpl
   */
  public XxcsoPvDefEOImpl getXxcsoPvDefEO()
  {
    return (XxcsoPvDefEOImpl)getAttributeInternal(XXCSOPVDEFEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoPvDefEOImpl
   */
  public void setXxcsoPvDefEO(XxcsoPvDefEOImpl value)
  {
    setAttributeInternal(XXCSOPVDEFEO, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number sortColumnDefId)
  {
    return new Key(new Object[] {sortColumnDefId});
  }


}